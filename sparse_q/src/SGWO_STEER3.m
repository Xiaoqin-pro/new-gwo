function [Best,T,info]=SGWO_STEER3(f,state,~,N,seed)
%SGWO_STEER3  Whole-algorithm runtime optimisation of G1+E+STEER (bitwise-identical semantics).
%   Optimisations, all of which preserve the random-number CONSUMPTION ORDER exactly (verified by
%   test_steer_opt_equivalence, which asserts a bitwise-identical trace/cost against SGWO_STEER):
%     1) G1 loop: six rand(1,D) draws -> one rand(1,6*D) draw per wolf;
%     2) gwoMove (external filler candidates): same 6->1 batching;
%     3) E single-centre shell: (rand + rand(1,D)) -> one rand(1,D+1) draw;
%     4) E credit-weighted centre pick: cumsum/weights hoisted out of the per-candidate call;
%     5) two-centre pick: the two initial randi draws issued in one call (rejection loop unchanged);
%     6) STEER trigger: N per-wolf rand(sAux) draws -> one batched rand(sAux,N,1).
%SGWO_STEER2  Same mechanism as SGWO_STEER, with one runtime optimisation:
%   the per-wolf trigger draws rand(sAux) are replaced by a single batched draw
%   rand(sAux,N,1) taken immediately before the G1 loop.  The values and their order are
%   identical (the G1 loop is the first consumer of sAux in a generation), so every random
%   number stream keeps the exact same state and the search trace must stay BITWISE identical.
%   Applied only for the random-direction variant (sdirSource='random'); the dir variant and
%   the gate-off STJ generations keep the original per-wolf behaviour.
%SGWO_STEER  Equal-length perturbation of G1 candidates on top of the frozen G1+E scaffold.
%   STJ variant (steerMode='stj'): identical perturbation, but only applied while the global best
%   has been stagnant for stjTau = max(stjTauMin, stjTauFrac*budget) real evaluations.
%   Gate off => frozen behaviour for that generation (no extra RNG consumption).
%   steerMode='none' : identical to SGWO_ABLATION (frozen behaviour)
%             'rand' : with probability succSteer, extend the G1 candidate by a random unit
%                      direction of length steerLambda*||xg-xwolf|| (vectorised implementation)
%             'dir'  : same trigger/length, direction taken from the verified G1 success-direction
%                      archive (sdirSource='g1'); falls back to no perturbation while empty.
%   候选池、领导、档案、接受规则与 FE 计费不变；只改变 G1 候选的方向覆盖。
%SGWO  Sparse-evaluation Grey Wolf Optimizer with budget scheduling
%      （sparse_q 研究分支的新算法；独立实现，不挪用 RASE-GWO 代码）
%
%   [Best,T,info]=SGWO(f,state,[],N,seed)
%
%   硬约束：未真实评价的候选不得参与任何适应度排序/领导更新/档案准入；
%   被接受的已验证位置与真实适应度严格一一对应；全部真实 FE 严格计费。
%
%   模式 state.mode：
%     'dense-async' 标准 GWO 语义（逐狼移动-评价-立即更新领导）——管线审计用，
%                   相同 init/seed 下必须与冻结 GWO.m 逐位一致（测试强制）；
%     'dense-sync'  同代批量候选、全部评价（B1 空白基线，同步领导更新）；
%     'sparse'      稀疏评价：每代生成 M≤2N 个廉价候选，仅 K 个真实评价。
%
%   候选来源（dense-sync / sparse）：
%     G1（N）：正规 GWO 领导聚合移动（逐狼、逐维 A/C 随机，a 随真实 FE 线性衰减）
%     G2（nG2）：围绕 alpha 的“成功步长壳”采样
%     E （nE）：已验证精英档案（非 alpha 优质区域）——单中心壳（credit 加权）
%                 + 双中心线段采样
%
%   筛选 state.screenPolicy：
%     'random'  从 M 个候选均匀随机挑 K（S1）
%     'directed'双路筛选（S2）：G 路取到 alpha 几何距离最小者；E 路按中心权重
%                w_c=1+credit_c 做“最大余数”名额分配，中心内取离中心最近者。
%
%   配额 state.quotaPolicy：
%     'fixed'  qE=state.quotaFixed（S3 扫描 {0.25,0.5,0.75}）
%     'random' 每 500 真实 FE 窗口从动作集均匀重抽（S4，同频率对照）
%     'q'      6 态×3 动作 Q-learning（S5）：
%              状态=FE 进度 3 档 × 真实停滞 2 档；动作=qE∈{0.25,0.5,0.75}
%              ε: 0.3→0.05 随真实 FE 线性衰减；α=0.1, γ=0.9
%              窗口奖励 = clip(相对 global-best 改善, [0,1]) + 0.1×(被记功评价比例)

% ==================== 选项 ====================
opt=struct( ...
    'mode','sparse', ...
    'K',50, 'kSchedule','fixed', 'kEnd',50, 'nG2',NaN, 'nE',NaN, ...
    'screenPolicy','directed', 'g1Share',0.5, 'stratG1','rotate', 'stratE','credit', 'debugSel',false, ...
    'quotaPolicy','fixed','quotaFixed',0.5, ...
    'quotaActions',[0.25 0.50 0.75], ...
    'qWindow',500, 'qAlpha',0.1, 'qGamma',0.9, ...
    'qEpsStart',0.30, 'qEpsEnd',0.05, 'qInitPrior',0, ...
    'archiveCap',24, 'dSepFrac',0.02, ...
    'succCap',25, 'stagnFrac',0.02, 'stagnBoost',0, 'boostThreshFrac',0.02, ...
    'steerMode','none', 'succSteer',0, 'succDirCap',20, 'steerLambda',0.5, 'g2Subset',0, 'g2Mode','shell', 'g2F',0.5, 'g2Pool','pool', ...
    'covSteerSource','wolves', 'covSteerEvery',20, 'covSteerBlend',0, 'covSteerShrink',0.10, ...
    'leaderMode','global', 'qdSepFrac',0.10, 'qdShare',0.5, 'qdRetries',5, ...
    'leaderAgg','equal', 'leaderTemp',0.10, 'spatialConvFrac',0.5, 'leaderTopo','global', 'knnK',10, 'leaderBlend',0.5, 'topoEvery',10, 'eLineMode','two', 'ePathMode','nearest', ...
    'topoPolicy','fixed', 'topoActions',[0 5 10 20], 'topoAlpha',0.1, 'topoGamma',0.9, 'topoEpsStart',0.30, 'topoEpsEnd',0.05, 'topoEpsDecay',0.995, 'topoInitPrior',0, ...
    'opPolicy','fixed', 'opFixed',1, 'opActions',[1 2 3 4], 'opAlpha',0.1, 'opGamma',0.9, 'opEpsStart',0.30, 'opEpsEnd',0.05, 'opEpsDecay',0.995, 'opExploreBonus',0.1, 'opF',0.5, 'opGaussianFrac',0.10, 'opOppNoise',0.05, 'opShare',0.5, 'opPhaseFrac',0.5, 'opDiffMode','arc', ...
    'stjTauFrac',0.02, 'stjTauMin',500, ...
    'sdirSource','mixed', ...   % mixed | g1 | g2e | random（方向归因审计用；默认 mixed = 冻结行为）
    'ablateG2',0, 'ablateE',0, 'alphaSingleE',0, 'sigmaFixFrac',0, ...  % 消融开关（默认全关 = 冻结行为）
    'farReserve',0, 'farMinDist',0.15, 'farE',0);
fn=fieldnames(state);
for k=1:numel(fn)
    if isfield(opt,fn{k}) && ~isempty(state.(fn{k}))
        opt.(fn{k})=state.(fn{k});
    end
end
assert(any(strcmpi(opt.steerMode,{'none','vec','rand','dir','perwolf','stj','dsaudit','cov'})),'Unknown steerMode.');
isDsAudit=strcmpi(opt.steerMode,'dsaudit');   % passive: frozen behaviour + DSE premise logging
isStj=strcmpi(opt.steerMode,'stj');
if isStj
    assert(strcmpi(opt.sdirSource,'random'),'STJ uses the random-direction perturbation.');
end
assert(opt.succSteer>=0 && opt.succSteer<=1,'succSteer out of range.');
isRandDir=strcmp(opt.sdirSource,'random');
isCovSteer=strcmpi(opt.steerMode,'cov');
isQD=~strcmpi(opt.leaderMode,'global');
recG1 = ~strcmp(opt.sdirSource,'g2e') && ~isRandDir;
recG2E= ~strcmp(opt.sdirSource,'g1')  && ~isRandDir;

X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch: state holds %d rows, N=%d.',N0,N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D,'Bound vectors must match D=%d.',D);
assert(budget>=N && budget==floor(budget),'Budget must be integer >= N.');
assert(all(isfinite(X),'all') && all(X>=lb & X<=ub,'all'), ...
    'Initial population must be finite and inside the bounds.');
span=norm(ub-lb);
stjTau=max(opt.stjTauMin,round(opt.stjTauFrac*budget));

if isnan(opt.nG2), opt.nG2=max(1,round(N/2)); end
if isnan(opt.nE),  opt.nE=N-opt.nG2; end
if strcmp(opt.mode,'dense-sync')
    opt.K=N; opt.nG2=0; opt.nE=0; opt.screenPolicy='none';
end
if strcmp(opt.mode,'dense-async')
    K=0; M=0;            % dense-async 模式不使用候选池
else
    K=opt.K; M=N+opt.nG2+opt.nE; Kgen=K;
    assert(K<=M && K>=1,'K must be in [1, M]');
end

% ==================== RNG 与状态 ====================
rng(seed,'twister');                       % 基流：候选生成
sAux=RandStream('mt19937ar','Seed',seed+424242);  % 筛选随机 / Q 探索（与基流分离）
sCov=RandStream('mt19937ar','Seed',seed+999001);  % 协方差控制专用流（不扰动主搜索）
sLead=RandStream('mt19937ar','Seed',seed+888777);  % QD 领导控制流（不扰动主搜索）
sPolicy=RandStream('mt19937ar','Seed',seed+666777);  % 领导拓扑动作流
sOp=RandStream('mt19937ar','Seed',seed+555777);  % G1 算子控制流
sOpPolicy=RandStream('mt19937ar','Seed',seed+444777);  % G1 算子选择流
clockStart=tic;
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D));
Beta=Alpha; Delta=Alpha;

% ---- 初始化（真实评价，计入预算） ----
Xv=X; fv=inf(N,1);
fe=0;
for i=1:N
    v=f(Xv(i,:));
    fe=fe+1;
    fv(i)=v;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,Xv(i,:),v);
    T(fe)=Alpha.Cost;
end
lastGB=fe;

% ---- 模块状态 ----
Arc=zeros(opt.archiveCap,D); Arcv=inf(opt.archiveCap,1); ArcN=0; ArcCred=zeros(opt.archiveCap,1);
succ=zeros(0,1); succPtr=0;
gensSince=zeros(N,1);      % 每只狼距上次被真实评价的代数（rotating G1 用）
sdir=zeros(opt.succDirCap,D); sdirN=0; sdirPtr=0;   % 已验证成功位移方向环形档案
Far=zeros(max(opt.farReserve,1),D); Farv=inf(max(opt.farReserve,1),1); FarN=0;  % 远处已验证盆地储备
nCandGen=0; nDistOps=0; nArcIns=0;
Q=zeros(6,numel(opt.quotaActions));
if opt.qInitPrior~=0, Q(:,1)=opt.qInitPrior; end   % 先验偏好动作1（q25）；仍为独立初始化
qActCount=zeros(1,numel(opt.quotaActions));
qStateCount=zeros(1,6);
qTrace=zeros(0,6);   % [fe, qE, action, stateStart, reward, gbImproved]
gen1Src=[NaN NaN NaN NaN];
steerTriggers=0; steerApplied=0;
opNow=opt.opFixed; opMask=false(N,1); nbrCache=[]; opQ=zeros(9,numel(opt.opActions)); opActCount=zeros(1,numel(opt.opActions)); opStateCount=zeros(1,9); opAct=1; opState=1; opEps=opt.opEpsStart; opTrace=zeros(0,5); topoQ=zeros(6,numel(opt.topoActions)); if opt.topoInitPrior~=0, topoQ(:,1)=opt.topoInitPrior; end; topoActCount=zeros(1,numel(opt.topoActions)); topoStateCount=zeros(1,6); topoAct=1; topoState=1; topoEps=opt.topoEpsStart; topoTrace=zeros(0,5);
covB=[]; covD=[]; covUpdates=0; covCondTrace=zeros(0,1);
whB=[]; whInv=[]; whEvery=max(5,round(opt.covSteerEvery));
stjGateGens=0; stjApplied=0;
daLastArc=0; daLastGB=0; daDualFE=0; daFirstDualFE=-1; daArcGapMax=0; daArcImpCnt=0;

impCnt=zeros(1,4); impMag=zeros(1,4);   % 消融：来源级真实改善次数/幅度
winEnd=fe+opt.qWindow; winGBStart=Alpha.Cost; winRecImp=0; winEvals=0;
stagnThresh=max(500,round(opt.stagnFrac*budget));
rounds=0;

% ---- 配额动作状态（q / random） ----
qE=opt.quotaFixed; aPrev=0; sPrev=0;
if strcmp(opt.quotaPolicy,'q') || strcmp(opt.quotaPolicy,'random')
    sPrev=stateIndex(fe,budget,lastGB,stagnThresh);
    [qE,aPrev]=chooseAction(opt,fe,budget,Q,sPrev,sAux);
end
if strcmpi(opt.topoPolicy,'q') || strcmpi(opt.topoPolicy,'random')
    topoState=stateIndex(fe,budget,lastGB,stagnThresh);
    if strcmpi(opt.topoPolicy,'q'), [topoAct,topoEps]=chooseTopoAction(opt,topoQ,topoState,sPolicy,topoEps); else, topoAct=randi(sPolicy,numel(opt.topoActions)); end
end
if strcmpi(opt.opPolicy,'q') || strcmpi(opt.opPolicy,'random')
    opState=stateIndex9(fe,budget,lastGB,stagnThresh);
    if strcmpi(opt.opPolicy,'q'), [opAct,opEps]=chooseOpAction(opt,opQ,opState,sOpPolicy,opEps); else, opAct=randi(sOpPolicy,numel(opt.opActions)); end
end

% ==================== dense-async：标准 GWO 语义（审计用） ====================
if strcmp(opt.mode,'dense-async')
    while fe<budget
        rounds=rounds+1;
        a=2-2*(fe/budget);
        for i=1:N
            if fe>=budget, break; end
            A1=2*a*rand(1,D)-a;  C1=2*rand(1,D);
            A2=2*a*rand(1,D)-a;  C2=2*rand(1,D);
            A3=2*a*rand(1,D)-a;  C3=2*rand(1,D);
            X1=alphaUse(i,:)-A1.*abs(C1.*alphaUse(i,:)-Xv(i,:));
            X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -Xv(i,:));
            X3=Delta.Vector-A3.*abs(C3.*Delta.Vector -Xv(i,:));
            xn=(X1+X2+X3)/3;
            xn=min(max(xn,lb),ub);
            Xv(i,:)=xn;
            v=f(xn);
            fe=fe+1;
            [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,xn,v);
            T(fe)=Alpha.Cost;
        end
    end
    Best=struct('Cost',Alpha.Cost,'Vector',Alpha.Vector);
    info=baseInfo(fe,rounds,T,clockStart,opt);
    return;
end

% ==================== 主循环（dense-sync / sparse） ====================
while fe<budget
    rounds=rounds+1;
    if strcmpi(opt.kSchedule,'up'), Kgen=round(K+(opt.kEnd-K)*fe/budget); elseif strcmpi(opt.kSchedule,'down'), Kgen=round(opt.kEnd+(K-opt.kEnd)*fe/budget); else, Kgen=K; end
    Kgen=max(1,min(M,Kgen));
    alphaUse=repmat(Alpha.Vector,N,1); if strcmpi(opt.opPolicy,'hybrid'), opMask=rand(sOp,N,1)<opt.opShare; elseif strcmpi(opt.opPolicy,'early'), opMask=repmat(fe<=opt.opPhaseFrac*budget,N,1); elseif strcmpi(opt.opPolicy,'late'), opMask=repmat(fe>opt.opPhaseFrac*budget,N,1); elseif strcmpi(opt.opPolicy,'rank'), [~,orank]=sort(fv,'ascend'); nd=round(opt.opShare*N); opMask=false(N,1); if nd>0, opMask(orank(max(1,N-nd+1):N))=true; end; end
    betaUse=repmat(Beta.Vector,N,1); deltaUse=repmat(Delta.Vector,N,1); qdBetaDist=NaN; qdDeltaDist=NaN; qdActive=0;
    if isQD
        pool=[Xv;Arc(1:ArcN,:)]; poolF=[fv;Arcv(1:ArcN)]; good=isfinite(poolF); pool=pool(good,:); poolF=poolF(good);
        if size(pool,1)>=3
            [~,po]=sort(poolF); sep=max(0,opt.qdSepFrac)*span; bi=[]; di=[]; sepEff=sep;
            for att=1:max(1,opt.qdRetries)
                dA=sqrt(sum((pool-repmat(pool(po(1),:),size(pool,1),1)).^2,2)); cand=po(dA(po)>=sepEff);
                if ~isempty(cand), bi=cand(1); break; end
                sepEff=sepEff/2;
            end
            if isempty(bi), bi=po(min(2,numel(po))); end
            sepEff=sep;
            for att=1:max(1,opt.qdRetries)
                dA=sqrt(sum((pool-repmat(pool(po(1),:),size(pool,1),1)).^2,2)); dB=sqrt(sum((pool-repmat(pool(bi,:),size(pool,1),1)).^2,2)); cand=po(min(dA,dB)>=sepEff);
                if ~isempty(cand), di=cand(1); break; end
                sepEff=sepEff/2;
            end
            if isempty(di), di=po(min(3,numel(po))); end
            if strcmpi(opt.leaderMode,'qdrand')
                dA=sqrt(sum((pool-repmat(pool(po(1),:),size(pool,1),1)).^2,2)); cb=po(dA(po)>=sep); if isempty(cb), cb=po(min(2,numel(po))); end; bi=cb(randi(sLead,numel(cb)));
                dB=sqrt(sum((pool-repmat(pool(bi,:),size(pool,1),1)).^2,2)); dA=sqrt(sum((pool-repmat(pool(po(1),:),size(pool,1),1)).^2,2)); cd=po(min(dA,dB)>=sep); if isempty(cd), cd=po(min(3,numel(po))); end; di=cd(randi(sLead,numel(cd)));
            end
            if strcmpi(opt.leaderMode,'qdhalf'), sel=rand(sLead,N,1)<=opt.qdShare; else, sel=true(N,1); end
            qdActive=sum(sel); betaUse(sel,:)=repmat(pool(bi,:),sum(sel),1); deltaUse(sel,:)=repmat(pool(di,:),sum(sel),1);
            qdBetaDist=norm(pool(bi,:)-pool(po(1),:)); qdDeltaDist=min(norm(pool(di,:)-pool(po(1),:)),norm(pool(di,:)-pool(bi,:)));
        end
    end
    if strcmpi(opt.topoPolicy,'q') || strcmpi(opt.topoPolicy,'random')
        topoK=opt.topoActions(topoAct);
        if topoK>0, effTopo='knn'; effK=topoK; else, effTopo='global'; effK=0; end
    else
        effTopo=opt.leaderTopo; effK=opt.knnK;
    end
    if any(strcmpi(effTopo,{'knn','knnall','knnrand','featknn','featknnall','featknnrand','featknnrandall'}))
        kk=min(N-1,max(2,round(effK)));
        if strcmpi(effTopo,'featknnrand') || strcmpi(effTopo,'featknnrandall')
            nbrOrd=zeros(N,kk); for i=1:N, cand=setdiff(1:N,i); nbrOrd(i,:)=cand(randperm(sLead,N-1,kk)); end
        elseif any(strcmpi(effTopo,{'featknn','featknnall'}))
            if isempty(nbrCache) || size(nbrCache,2)~=kk || mod(rounds-1,max(1,round(opt.topoEvery)))==0
                fr=zeros(N,1); [~,fo]=sort(fv); fr(fo)=(1:N)'/max(N,1); st=gensSince/max(1,max(gensSince)); da=sqrt(sum((Xv-repmat(Alpha.Vector,N,1)).^2,2))/span; dm=sqrt(sum((Xv-repmat(mean(Xv,1),N,1)).^2,2))/span; Ff=[fr,st,da,dm]; Ff=(Ff-repmat(mean(Ff,1),N,1))./max(repmat(std(Ff,0,1),N,1),1e-12); Dmat=sqrt(max(0,sum(Ff.^2,2)+sum(Ff.^2,2)'-2*(Ff*Ff'))); Dmat(1:N+1:end)=inf; [~,nbrCache]=sort(Dmat,2,'ascend');
            end
            nbrOrd=nbrCache;
        else
            Dmat=sqrt(max(0,sum(Xv.^2,2)+sum(Xv.^2,2)'-2*(Xv*Xv'))); Dmat(1:N+1:end)=inf; [~,nbrOrd]=sort(Dmat,2,'ascend');
        end
        for i=1:N
            if strcmpi(effTopo,'knnrand'), cand=setdiff(1:N,i); nb=cand(randperm(sLead,N-1,kk)); elseif strcmpi(effTopo,'featknnrand'), nb=nbrOrd(i,1:kk); else, nb=nbrOrd(i,1:kk); end
            [~,bo]=sort(fv(nb)); nb=nb(bo); bb=Xv(nb(1),:); dd=Xv(nb(min(2,numel(nb))),:); zz=max(0,min(1,opt.leaderBlend)); if strcmpi(opt.topoPolicy,'q') || strcmpi(opt.topoPolicy,'random'), zz=1; end
            if any(strcmpi(effTopo,{'knnall','featknnall','featknnrandall'})), alphaUse(i,:)=(1-zz)*Alpha.Vector+zz*bb; betaUse(i,:)=(1-zz)*Beta.Vector+zz*Xv(nb(min(2,numel(nb))),:); deltaUse(i,:)=(1-zz)*Delta.Vector+zz*Xv(nb(min(3,numel(nb))),:); else, betaUse(i,:)=(1-zz)*Beta.Vector+zz*bb; deltaUse(i,:)=(1-zz)*Delta.Vector+zz*dd; end
        end
        qdActive=N;
    end
    if isCovSteer && (rounds==1 || mod(rounds-1,opt.covSteerEvery)==0)
        switch lower(opt.covSteerSource)
            case 'archive'
                if ArcN>=2
                    [~,ao]=sort(Arcv(1:ArcN)); Xc=Arc(ao(1:min(ArcN,max(2,ArcN))),:);
                else, Xc=Xv; end
            case 'mixed'
                [~,wo]=sort(fv); mw=min(N,max(2,round(0.5*N))); Xc=[Xv(wo(1:mw),:); Arc(1:ArcN,:)];
                Xc=unique(Xc,'rows','stable');
            case 'wolves_random'
                mw=min(N,max(2,round(0.5*N))); rp=randperm(sCov,N); Xc=Xv(rp(1:mw),:);
            otherwise
                [~,wo]=sort(fv); mw=min(N,max(2,round(0.5*N))); Xc=Xv(wo(1:mw),:);
        end
        if size(Xc,1)>=2
            xm=mean(Xc,1); Xcc=Xc-repmat(xm,size(Xc,1),1); Cc=(Xcc'*Xcc)/(size(Xc,1)-1); Cc=(Cc+Cc')/2;
            sc=mean(diag(Cc)); if isfinite(sc) && sc>0
                Cc=(1-opt.covSteerShrink)*Cc+opt.covSteerShrink*sc*eye(D); [covB,L]=eig(Cc); L=max(diag(L),1e-12); covD=sqrt(L)';
                if strcmpi(opt.covSteerSource,'shuffled'), perm=randperm(sCov,D); covB=covB(:,perm); covD=covD(perm); end
                covUpdates=covUpdates+1; covCondTrace(end+1,1)=max(L)/min(L);
            else, covB=[]; covD=[]; end
        else, covB=[]; covD=[]; end
    end
    aA=2-2*(fe/budget);      % 与标准 GWO 相同的线性衰减（按真实 FE）

    % 白化差分缓存：每 whEvery 代用当前种群上半部估计协方差，供 opDiffMode='whiten' 使用
    if (rounds==1 || mod(rounds-1,whEvery)==0)
        [~,wo]=sort(fv); mw=min(N,max(2,round(0.5*N))); Xw=Xv(wo(1:mw),:);
        xmw=mean(Xw,1); Xwc=Xw-repmat(xmw,size(Xw,1),1); Cw=(Xwc'*Xwc)/(size(Xw,1)-1); Cw=(Cw+Cw')/2;
        [whB,Lw]=eig(Cw); Lw=max(diag(Lw),1e-12);
        if all(isfinite(Lw)) && all(isfinite(whB(:)))
            whInv=1./sqrt(Lw);
        else, whB=[]; whInv=[]; end
    end

    % ---- 1) 生成候选池（廉价；不消耗真实 FE） ----
    Y=zeros(M,D); src=zeros(M,1); par=zeros(M,1); ctr=zeros(M,1);
    m=0;
    trigR=zeros(N,1);
    if isRandDir && opt.succSteer>0
        drawTrig=false;
        if strcmpi(opt.steerMode,'perwolf') || isDsAudit
            drawTrig=true;                       % succEff = succSteer > 0 for the whole generation
        elseif (isStj) && (fe-lastGB)>=stjTau
            drawTrig=true;                       % STJ gate open for this generation
        end
        % vectorised modes ('vec','rand','dir') already draw their triggers in batch; leave them as-is
        if drawTrig, trigR=rand(sAux,N,1); end   % 与逐狼 rand(sAux) 完全同值同序
    end
    stjGateNow=false;
    if isStj
        stjGateNow=(fe-lastGB)>=stjTau;
        if stjGateNow, stjGateGens=stjGateGens+1; end
    end
    if any(strcmpi(opt.steerMode,{'vec','rand','dir'}))   % 'perwolf' 走冻结逐狼路径（与 SGWO_ABLATION 逐位一致）
        % ---- G1（向量化扰动版；none 仍走冻结逐狼路径） ----
        A1m=2*aA*rand(N,D)-aA; C1m=2*rand(N,D);
        A2m=2*aA*rand(N,D)-aA; C2m=2*rand(N,D);
        A3m=2*aA*rand(N,D)-aA; C3m=2*rand(N,D);
        X1=Alpha.Vector-A1m.*abs(C1m.*Alpha.Vector-Xv);
        X2=Beta.Vector -A2m.*abs(C2m.*Beta.Vector -Xv);
        X3=Delta.Vector-A3m.*abs(C3m.*Delta.Vector-Xv);
        Xg=(X1+X2+X3)/3;
        trig=rand(sAux,N,1)<opt.succSteer;
        if strcmpi(opt.steerMode,'vec'), trig(:)=false; end   % 向量化对照臂：不施加扰动
        steerTriggers=steerTriggers+sum(trig);
        if any(trig)
            stepv=sqrt(sum((Xg-Xv).^2,2));
            if strcmpi(opt.steerMode,'rand')
                U=randn(N,D); Un=U./max(sqrt(sum(U.^2,2)),1e-300);
            elseif sdirN>0
                pr=randi(sAux,sdirN,N,1); Un=zeros(N,D);
                for ii=1:N, Un(ii,:)=sdir(pr(ii),:); end
                Un=Un./max(sqrt(sum(Un.^2,2)),1e-300);
            else
                Un=zeros(N,D);
            end
            Xg(trig,:)=Xg(trig,:)+opt.steerLambda*stepv(trig).*Un(trig,:);
            steerApplied=steerApplied+sum(trig & any(Un~=0,2));
        end
        Y(1:N,:)=min(max(Xg,lb),ub);
        src(1:N)=1; par(1:N)=(1:N)';
        m=N;
    else
    for i=1:N     % G1
        m=m+1;
        R6=rand(1,6*D);                       % 与六次 rand(1,D) 完全同值同序
        A1=2*aA*R6(1:D)-aA;         C1=2*R6(D+1:2*D);
        A2=2*aA*R6(2*D+1:3*D)-aA;   C2=2*R6(3*D+1:4*D);
        A3=2*aA*R6(4*D+1:5*D)-aA;   C3=2*R6(5*D+1:6*D);
        X1=alphaUse(i,:)-A1.*abs(C1.*alphaUse(i,:)-Xv(i,:));
        X2=betaUse(i,:)-A2.*abs(C2.*betaUse(i,:)-Xv(i,:));
        X3=deltaUse(i,:)-A3.*abs(C3.*deltaUse(i,:)-Xv(i,:));
        if strcmpi(opt.leaderAgg,'dist')
            d1=sqrt(sum((X1-Xv(i,:)).^2,2)); d2=sqrt(sum((X2-Xv(i,:)).^2,2)); d3=sqrt(sum((X3-Xv(i,:)).^2,2));
            wg=exp(-[d1 d2 d3]/max(1e-12,opt.leaderTemp*span)); wg=wg/sum(wg); xg=wg(1)*X1+wg(2)*X2+wg(3)*X3;
        elseif strcmpi(opt.leaderAgg,'fit')
            cf=[Alpha.Cost Beta.Cost Delta.Cost]; rel=(cf-min(cf))/max(1,abs(min(cf))); wg=exp(-rel/max(1e-12,opt.leaderTemp)); wg=wg/sum(wg); xg=wg(1)*X1+wg(2)*X2+wg(3)*X3;
        elseif strcmpi(opt.leaderAgg,'random')
            wg=rand(sLead,1,3); wg=wg/sum(wg); xg=wg(1)*X1+wg(2)*X2+wg(3)*X3;
        else
            xg=(X1+X2+X3)/3;
        end
        if strcmpi(opt.opPolicy,'q') || strcmpi(opt.opPolicy,'random')
            opNow=opt.opActions(opAct);
        elseif any(strcmpi(opt.opPolicy,{'hybrid','early','late','rank'}))
            if opMask(i), opNow=2; else, opNow=1; end
        elseif strcmpi(opt.opPolicy,'fixed')
            opNow=opt.opFixed;
        end
        if opNow==2
            r1=randi(sOp,N); while r1==i, r1=randi(sOp,N); end
            if strcmpi(opt.opDiffMode,'nowarc')
                pOp=Xv; r2=randi(sOp,N); while r2==i || r2==r1, r2=randi(sOp,N); end
            else
                pOp=[Xv;Arc(1:ArcN,:)]; r2=randi(sOp,size(pOp,1)); while r2==i || r2==r1, r2=randi(sOp,size(pOp,1)); end
            end
            dv=Xv(r1,:)-pOp(r2,:);
            if strcmpi(opt.opDiffMode,'shuffle'), dv=dv(randperm(sOp,D)); end
            if strcmpi(opt.opDiffMode,'random')
                u1=lb+rand(sOp,1,D).*(ub-lb); u2=lb+rand(sOp,1,D).*(ub-lb); dv=u1-u2;
            end
            if strcmpi(opt.opDiffMode,'whiten') && ~isempty(whB) && ~isempty(whInv)
                dv=dv*(whB*diag(whInv)*whB');
            elseif strcmpi(opt.opDiffMode,'rot') && ~isempty(whB)
                dv=dv*whB*whB';
            end
            xg=Xv(i,:)+opt.opF*(Alpha.Vector-Xv(i,:))+opt.opF*dv;
        elseif opNow==5
            r1=randi(sOp,N); while r1==i, r1=randi(sOp,N); end
            r2=randi(sOp,N); while r2==i || r2==r1, r2=randi(sOp,N); end
            xg=xg+opt.opF*(Xv(r1,:)-Xv(r2,:));
        elseif opNow==3
            sigOp=opt.opGaussianFrac*(1-fe/budget)*span/sqrt(D); xg=Alpha.Vector+sigOp*randn(sOp,1,D);
        elseif opNow==4
            xg=lb+ub-Xv(i,:)+opt.opOppNoise*span/sqrt(D)*randn(sOp,1,D);
        end
        succEff=opt.succSteer; if opNow==3 || opNow==4, succEff=0; end
        if isStj && ~stjGateNow, succEff=0; end
        if isDsAudit, succEff=0; end
        if isCovSteer
            if succEff>0 && trigR(i)<succEff
                sd=randn(1,D);
                if ~isempty(covB) && norm(sd)>0
                    iso=sd/norm(sd); sdc=(sd.*covD)*covB'; sdc=sdc/max(norm(sdc),1e-300);
                    beta=max(0,min(1,opt.covSteerBlend)); sd=(1-beta)*iso+beta*sdc;
                end
                nrm=norm(sd);
                if nrm>0
                    stepv=norm(xg-Xv(i,:)); xg=xg+opt.steerLambda*(sd/nrm)*stepv;
                    if isStj, stjApplied=stjApplied+1; else, steerApplied=steerApplied+1; end
                end
            end
        elseif isRandDir
            if succEff>0 && trigR(i)<succEff
                sd=randn(1,D); nrm=norm(sd);
                if nrm>0
                    stepv=norm(xg-Xv(i,:));
                    xg=xg+opt.steerLambda*(sd/nrm)*stepv;
                    if isStj, stjApplied=stjApplied+1; else, steerApplied=steerApplied+1; end
                    if isStj, stjApplied=stjApplied+1; else, steerApplied=steerApplied+1; end   % 等长随机方向对照（非方向信息）
                end
            end
        elseif succEff>0 && sdirN>0 && rand(sAux)<succEff
            j=randi(sAux,sdirN);
            sd=sdir(j,:); nrm=norm(sd);
            if nrm>0
                stepv=norm(xg-Xv(i,:));
                xg=xg+opt.steerLambda*(sd/nrm)*stepv;   % 沿已验证成功方向延长一步（真实成功信息复用）
            end
        end
        Y(m,:)=min(max(xg,lb),ub);
        src(m)=1; par(m)=i;
    end
    if strcmpi(opt.steerMode,'perwolf') && opt.succSteer>0
        steerTriggers=steerTriggers+0;   % 逐狼路径的触发计数由下方 SteerTrace 统计
    end
    end
    sig=shellSigma(succ,span,D);
    if opt.stagnBoost>0 && (fe-lastGB)>=max(500,round(opt.boostThreshFrac*budget))
        sigB=sig*opt.stagnBoost;    % 停滞触发的"跳出"半径放大（仅作用于壳类候选）
    else
        sigB=sig;
    end
    sigG2=sigB;
    if opt.sigmaFixFrac>0, sigG2=opt.sigmaFixFrac*span*sqrt(3/D); end   % A4: 固定尺度（不随成功历史变化）
    for j=1:opt.nG2  % G2
        m=m+1;
        if opt.ablateG2
            iw=mod(j-1,size(Xv,1))+1;                      % 消融：标准 GWO 候选填补槽位
            Y(m,:)=gwoMove(aA,Alpha,Beta,Delta,Xv(iw,:),lb,ub);
            src(m)=4; ctr(m)=0;
        elseif strcmpi(opt.g2Mode,'diffa')
            % toward-alpha 差分候选：x_r1 + F*(alpha - x_r1) + F*(x_r2 - x_r3)
            if strcmpi(opt.g2Pool,'wolves'), pG=Xv; else, pG=[Xv;Arc(1:ArcN,:)]; end; nG=size(pG,1);
            r1=randi(sAux,nG); r2=randi(sAux,nG);
            while r2==r1, r2=randi(sAux,nG); end
            r3=randi(sAux,nG);
            while r3==r1 || r3==r2, r3=randi(sAux,nG); end
            Y(m,:)=min(max(pG(r1,:)+opt.g2F*(Alpha.Vector-pG(r1,:))+opt.g2F*(pG(r2,:)-pG(r3,:)),lb),ub);
            src(m)=2; ctr(m)=0;
        elseif strcmpi(opt.g2Mode,'diff')
            % 差分候选：从狼群+已验证档案中取三个不同个体，x_r1 + F*(x_r2 - x_r3)
            if strcmpi(opt.g2Pool,'wolves'), pG=Xv; else, pG=[Xv;Arc(1:ArcN,:)]; end; nG=size(pG,1);
            r1=randi(sAux,nG); r2=randi(sAux,nG);
            while r2==r1, r2=randi(sAux,nG); end
            r3=randi(sAux,nG);
            while r3==r1 || r3==r2, r3=randi(sAux,nG); end
            Y(m,:)=min(max(pG(r1,:)+opt.g2F*(pG(r2,:)-pG(r3,:)),lb),ub);
            src(m)=2; ctr(m)=0;
        elseif opt.g2Subset>0
            nd=max(1,round(opt.g2Subset*D));
            dims=randperm(sAux,D,nd);
            pert=zeros(1,D); pert(dims)=sigG2*(2*rand(1,nd)-1);
            Y(m,:)=min(max(Alpha.Vector+pert,lb),ub);   % 坐标稀疏扰动（G2 精化）
            src(m)=2;
        else
            Y(m,:)=min(max(Alpha.Vector+sigG2*(2*rand(1,D)-1),lb),ub);
            src(m)=2;
        end
    end
    if ArcN>0
        ww=(1+ArcCred(1:ArcN)); cwCache=cumsum(ww/sum(ww));   % 每代一次（ArcCred 在池生成期间不变）
        if strcmpi(opt.eLineMode,'graph') && ArcN>=2, DArc=sqrt(max(0,sum(Arc(1:ArcN,:).^2,2)+sum(Arc(1:ArcN,:).^2,2)'-2*(Arc(1:ArcN,:)*Arc(1:ArcN,:)'))); DArc(1:ArcN+1:end)=inf; end
    else
        cwCache=[];
    end
    for j=1:opt.nE  % E
        m=m+1;
        if opt.ablateE
            iw=mod(j-1,size(Xv,1))+1;                      % 消融：标准 GWO 候选填补槽位
            Y(m,:)=gwoMove(aA,Alpha,Beta,Delta,Xv(iw,:),lb,ub);
            src(m)=4; ctr(m)=0;
        elseif opt.alphaSingleE
            Y(m,:)=min(max(Alpha.Vector+sigB*(2*rand(1,D)-1),lb),ub);   % A5: Alpha 单中心替代档案多中心
            src(m)=3; ctr(m)=0;
        elseif opt.farE>0 && j>(opt.nE-opt.farE) && FarN>0
            fc=randi(sAux,FarN);
            Y(m,:)=min(max(Far(fc,:)+sigB*(2*rand(1,D)-1),lb),ub);   % 远处已验证盆地壳
            src(m)=3; ctr(m)=0;
        elseif ArcN==0
            Y(m,:)=min(max(Alpha.Vector+sigB*(2*rand(1,D)-1),lb),ub);
            src(m)=3; ctr(m)=0;
        elseif mod(j,2)==1 || ArcN==1
            c=find(rand(sAux)<=cwCache,1); if isempty(c), c=ArcN; end   % 与原 pickWeighted 同值
            RR=rand(1,D+1);                                            % 原 (rand + rand(1,D)) 同值同序
            Y(m,:)=min(max(Arc(c,:)+sigB*(0.5+RR(1))*(2*RR(2:end)-1),lb),ub);
            src(m)=3; ctr(m)=c;
        else
            if strcmpi(opt.eLineMode,'graph') && ArcN>=3
                c1=find(rand(sAux)<=cwCache,1); if isempty(c1), c1=ArcN; end
                [~,ord1]=sort(DArc(c1,1:ArcN),'ascend'); c2=ord1(1); if c2==c1, c2=ord1(2); end
                [~,ord2]=sort(DArc(c2,1:ArcN),'ascend'); c3=ord2(find(ord2~=c1 & ord2~=c2,1));
                lam=0.15+0.7*rand(sAux); path=(1-lam)^2*Arc(c1,:)+2*(1-lam)*lam*Arc(c2,:)+lam^2*Arc(c3,:);
            elseif strcmpi(opt.eLineMode,'randompath') && ArcN>=3
                cc=randperm(sAux,ArcN,3); c1=cc(1); lam=0.15+0.7*rand(sAux); path=(1-lam)^2*Arc(cc(1),:)+2*(1-lam)*lam*Arc(cc(2),:)+lam^2*Arc(cc(3),:);
            else
                [c1,c2]=pickTwoCenters(ArcN,sAux); lam=0.15+0.7*rand(sAux); path=Arc(c1,:)+lam*(Arc(c2,:)-Arc(c1,:));
            end
            Y(m,:)=min(max(path+0.25*sigB*(2*rand(1,D)-1),lb),ub);
            src(m)=3; ctr(m)=c1;
        end
    end
    nCandGen=nCandGen+M;

    % ---- 2) 筛选 K 个候选 ----（统一入口：selectCandidates 子函数）
    if strcmp(opt.mode,'dense-sync')
        sel=1:M;
    else
        [sel,nd]=selectCandidates(opt,qE,Kgen,Y,src,par,ctr,Alpha,Arc,ArcN,ArcCred,span,sAux,gensSince);
        nDistOps=nDistOps+nd;
    end
    sel=sort(sel(:))';
    if rounds==1, gen1Src=[sum(src(sel)==1), sum(src(sel)==2), sum(src(sel)==3), sum(src(sel)==4)]; end

    % ---- 3) 逐候选真实评价 + 原子提交 ----
    for t=1:numel(sel)
        if fe>=budget, break; end
        j=sel(t);
        y=Y(j,:);
        v=f(y);
        fe=fe+1;
        gbImpBefore=v<Alpha.Cost;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,y,v);
        T(fe)=Alpha.Cost;

        recImp=false; arcImp=false;
        if src(j)==1
            i=par(j); ref=Xv(i,:); refF=fv(i);
            if v<refF
                recImp=true;
                d=norm(y-ref);
                impCnt(1)=impCnt(1)+1; impMag(1)=impMag(1)+(refF-v);
                if numel(succ)<opt.succCap, succ(end+1,1)=d; else, succPtr=mod(succPtr,opt.succCap)+1; succ(succPtr)=d; end
                if recG1
                    sdirPtr=mod(sdirPtr,opt.succDirCap)+1;
                    sdirN=min(sdirN+1,opt.succDirCap);
                    sdir(sdirPtr,:)=y-ref;
                end
            end
            Xv(i,:)=y; fv(i)=v;
            gensSince(i)=0;
        else
            [worstF,wi]=max(fv);
            if v<worstF
                ref=Xv(wi,:);
                Xv(wi,:)=y; fv(wi)=v;
                recImp=true;
                d=norm(y-ref);
                impCnt(src(j))=impCnt(src(j))+1; impMag(src(j))=impMag(src(j))+(worstF-v);
                if numel(succ)<opt.succCap, succ(end+1,1)=d; else, succPtr=mod(succPtr,opt.succCap)+1; succ(succPtr)=d; end
                if recG2E
                    sdirPtr=mod(sdirPtr,opt.succDirCap)+1;
                    sdirN=min(sdirN+1,opt.succDirCap);
                    sdir(sdirPtr,:)=y-ref;
                end
            end
        end

        % 档案：仅真实评价进入；严格更优才可能替换/插入（含适度分离规则）
        if ArcN==0
            ArcN=1; Arc(1,:)=y; Arcv(1)=v; nArcIns=nArcIns+1; arcImp=true;
        else
            if ArcN<opt.archiveCap
                [dmin,ni]=nearestIdx(y,Arc,ArcN);
                if v<max(Arcv(1:ArcN))
                    if dmin/span>=opt.dSepFrac
                        ArcN=ArcN+1; Arc(ArcN,:)=y; Arcv(ArcN)=v;
                        nArcIns=nArcIns+1; arcImp=true;
                    elseif v<Arcv(ni)
                        Arc(ni,:)=y; Arcv(ni)=v;
                    end
                end
            else
                [worstA,wa]=max(Arcv);
                if v<worstA
                    [dmin,ni]=nearestIdx(y,Arc,ArcN);
                    if dmin/span>=opt.dSepFrac
                        Arc(wa,:)=y; Arcv(wa)=v; ArcCred(wa)=0;
                        nArcIns=nArcIns+1; arcImp=true;
                    elseif v<Arcv(ni)
                        Arc(ni,:)=y; Arcv(ni)=v;
                    end
                end
            end
        end

        if opt.farReserve>0
            if norm(y-Alpha.Vector)/span>=opt.farMinDist
                if FarN<opt.farReserve
                    FarN=FarN+1; Far(FarN,:)=y; Farv(FarN)=v;
                elseif v<max(Farv(1:FarN))
                    [~,fw]=max(Farv(1:FarN)); Far(fw,:)=y; Farv(fw)=v;
                end
            end
        end
        if src(j)==3 && ctr(j)>0 && (recImp || arcImp)
            ArcCred(ctr(j))=ArcCred(ctr(j))+1;
        end
        if recImp || arcImp, winRecImp=winRecImp+1; end
        winEvals=winEvals+1;
        if gbImpBefore, lastGB=fe; end
        if isDsAudit
            if gbImpBefore, daLastGB=fe; end
            if arcImp, daLastArc=fe; daArcImpCnt=daArcImpCnt+1; end
            daArcGapMax=max(daArcGapMax,fe-daLastArc);
            if (fe-daLastGB)>=stjTau && (fe-daLastArc)>=stjTau
                daDualFE=daDualFE+1;
                if daFirstDualFE<0, daFirstDualFE=fe; end
            end
        end

        % ---- 配额窗口结算（每 qWindow 真实 FE 一次） ----
        if fe>=winEnd
            gbNow=Alpha.Cost;
            denom=max([abs(winGBStart),abs(gbNow),1e-300]);
            rGb=max(0,min(1,(winGBStart-gbNow)/denom));
            rSec=winRecImp/max(winEvals,1);
            rew=rGb+0.1*rSec;
            gbFlag=double(rGb>0);
            if strcmp(opt.quotaPolicy,'q')
                sNow=stateIndex(fe,budget,lastGB,stagnThresh);
                Q(sPrev,aPrev)=Q(sPrev,aPrev)+opt.qAlpha*(rew+opt.qGamma*max(Q(sNow,:))-Q(sPrev,aPrev));
                qStateCount(sPrev)=qStateCount(sPrev)+1;
                qActCount(aPrev)=qActCount(aPrev)+1;
                qTrace(end+1,:)=[fe,qE,aPrev,sPrev,rew,gbFlag]; %#ok<AGROW>
                [qE,aPrev]=chooseAction(opt,fe,budget,Q,sNow,sAux);
                sPrev=sNow;
            elseif strcmp(opt.quotaPolicy,'random')
                qStateCount(sPrev)=qStateCount(sPrev)+1;
                qActCount(aPrev)=qActCount(aPrev)+1;
                qTrace(end+1,:)=[fe,qE,aPrev,sPrev,rew,gbFlag]; %#ok<AGROW>
                aPrev=randi(sAux,numel(opt.quotaActions));
                qE=opt.quotaActions(aPrev);
            else
                qTrace(end+1,:)=[fe,qE,0,0,rew,gbFlag]; %#ok<AGROW>
            end
            winEnd=fe+opt.qWindow; winGBStart=Alpha.Cost; winRecImp=0; winEvals=0;
            if strcmpi(opt.topoPolicy,'q') || strcmpi(opt.topoPolicy,'random')
                sNowT=stateIndex(fe,budget,lastGB,stagnThresh);
                if strcmpi(opt.topoPolicy,'q')
                    topoQ(topoState,topoAct)=topoQ(topoState,topoAct)+opt.topoAlpha*(rew+opt.topoGamma*max(topoQ(sNowT,:))-topoQ(topoState,topoAct));
                    topoStateCount(topoState)=topoStateCount(topoState)+1; topoActCount(topoAct)=topoActCount(topoAct)+1;
                    topoTrace(end+1,:)=[fe,topoAct,topoState,rew,gbFlag];
                    [topoAct,topoEps]=chooseTopoAction(opt,topoQ,sNowT,sPolicy,topoEps);
                else
                    topoStateCount(topoState)=topoStateCount(topoState)+1; topoActCount(topoAct)=topoActCount(topoAct)+1;
                    topoTrace(end+1,:)=[fe,topoAct,topoState,rew,gbFlag]; topoAct=randi(sPolicy,numel(opt.topoActions));
                end
                topoState=sNowT;
            end
            if strcmpi(opt.opPolicy,'q') || strcmpi(opt.opPolicy,'random')
                sNowO=stateIndex9(fe,budget,lastGB,stagnThresh);
                rwO=rew; if opt.opActions(opAct)>=3, rwO=rwO+opt.opExploreBonus; end
                if strcmpi(opt.opPolicy,'q')
                    opQ(opState,opAct)=opQ(opState,opAct)+opt.opAlpha*(rwO+opt.opGamma*max(opQ(sNowO,:))-opQ(opState,opAct));
                    opStateCount(opState)=opStateCount(opState)+1; opActCount(opAct)=opActCount(opAct)+1; opTrace(end+1,:)=[fe,opAct,opState,rwO,gbFlag];
                    [opAct,opEps]=chooseOpAction(opt,opQ,sNowO,sOpPolicy,opEps);
                else
                    opStateCount(opState)=opStateCount(opState)+1; opActCount(opAct)=opActCount(opAct)+1; opTrace(end+1,:)=[fe,opAct,opState,rwO,gbFlag]; opAct=randi(sOpPolicy,numel(opt.opActions));
                end
                opState=sNowO;
            end
        end
    end
end

% ==================== 输出 ====================
Best=struct('Cost',Alpha.Cost,'Vector',Alpha.Vector);
info=baseInfo(fe,rounds,T,clockStart,opt);
info.FinalPopulation=Xv; info.FinalFitness=fv;
info.FinalArchive=Arc(1:ArcN,:); info.FinalArchiveFitness=Arcv(1:ArcN);
info.QuotaTrace=qTrace;
info.QTable=Q;
info.QActionCounts=qActCount;
info.QStateVisits=qStateCount;
info.NCandidateGenerated=nCandGen;
info.NDistanceOps=nDistOps;
info.NArchiveInserts=nArcIns;
info.ArchiveSize=ArcN;
info.K=opt.K; info.KSchedule=opt.kSchedule; info.KEnd=opt.kEnd;
info.Gen1SrcCounts=gen1Src;
info.FarN=FarN;
info.FarE=opt.farE;
info.ImpCnt=impCnt;
info.ImpMag=impMag;
info.SteerOn=~strcmpi(opt.steerMode,'none');
info.DsAuditOn=isDsAudit;
info.DaArcImpCnt=daArcImpCnt;
info.DaArcGapMax=daArcGapMax;
info.DaDualFE=daDualFE;
info.DaFirstDualFE=daFirstDualFE;
info.DaTau=stjTau;
info.StjOn=isStj;
info.StjTau=stjTau;
info.StjGateGens=stjGateGens;
info.StjApplied=stjApplied;
info.StjGateRate=stjGateGens/max(rounds,1);
info.SteerMode=opt.steerMode;
info.SteerProb=opt.succSteer;
info.SteerLambda=opt.steerLambda;
info.SteerTriggers=steerTriggers;
info.SteerApplied=steerApplied;
info.CovSteerOn=double(isCovSteer); info.CovSteerSource=opt.covSteerSource; info.CovSteerEvery=opt.covSteerEvery;
info.CovSteerBlend=opt.covSteerBlend; info.CovSteerUpdates=covUpdates; info.CovSteerCondMedian=median(covCondTrace);
info.OpPolicy=opt.opPolicy; info.OpFixed=opt.opFixed; info.OpNow=opNow; info.OpShare=opt.opShare; info.OpPhaseFrac=opt.opPhaseFrac; info.OpQ=opQ; info.OpActCounts=opActCount; info.OpStateVisits=opStateCount; info.OpTrace=opTrace; info.OpActPct=opActCount/max(sum(opActCount),1); info.OpQMean=mean(opQ,1);
info.OpDiffMode=opt.opDiffMode; info.OpF=opt.opF;
info.LeaderMode=opt.leaderMode; info.QDSepFrac=opt.qdSepFrac; info.QDShare=opt.qdShare; info.QDActiveMean=qdActive; info.QDBetaDist=qdBetaDist; info.QDDeltaDist=qdDeltaDist;
info.LeaderAgg=opt.leaderAgg; info.LeaderTemp=opt.leaderTemp; info.SpatialConvFrac=opt.spatialConvFrac; info.LeaderTopo=opt.leaderTopo; info.KNNK=opt.knnK; info.LeaderBlend=opt.leaderBlend; info.TopoPolicy=opt.topoPolicy; info.TopoQ=topoQ; info.TopoActCounts=topoActCount; info.TopoStateVisits=topoStateCount; info.TopoTrace=topoTrace; info.TopoActPct=topoActCount/max(sum(topoActCount),1); info.TopoQMean=mean(topoQ,1); info.TopoEvery=opt.topoEvery; info.ELineMode=opt.eLineMode; info.EPathMode=opt.ePathMode;
info.SteerRate=steerApplied/max(N*rounds,1);
end

% ==================== 辅助函数 ====================
function info=baseInfo(fe,rounds,T,clockStart,opt)
info=struct('Evaluations',fe,'Rounds',rounds,'MeanEvalsPerRound',fe/max(rounds,1), ...
    'WallClock',toc(clockStart),'Algorithm',sprintf('SGWO(%s,%s,%s,K=%d)', ...
    opt.mode,opt.screenPolicy,opt.quotaPolicy,opt.K));
end

function s=stateIndex(fe,budget,lastGB,stagnThresh)
if fe/budget<0.3, p=1; elseif fe/budget<0.7, p=2; else, p=3; end
if (fe-lastGB)<stagnThresh, g=1; else, g=2; end
s=(p-1)*2+g;
end

function [a,eps]=chooseOpAction(opt,Q,s,sOpPolicy,eps)
if rand(sOpPolicy)<eps, a=randi(sOpPolicy,numel(opt.opActions)); else, [~,a]=max(Q(s,:)); end
eps=max(opt.opEpsEnd,eps*opt.opEpsDecay);
end
function s=stateIndex9(fe,budget,lastGB,stagnThresh)
prog=min(3,floor(3*fe/max(budget,1))+1); st=fe-lastGB; if st<stagnThresh, sb=1; elseif st<2*stagnThresh, sb=2; else, sb=3; end
s=(prog-1)*3+sb;
end
function [a,eps]=chooseTopoAction(opt,Q,s,sPolicy,eps)
if rand(sPolicy)<eps, a=randi(sPolicy,numel(opt.topoActions)); else, [~,a]=max(Q(s,:)); end
eps=max(opt.topoEpsEnd,eps*opt.topoEpsDecay);
end
function [qE,ai]=chooseAction(opt,fe,budget,Q,s,sAux)
epsNow=opt.qEpsStart+(opt.qEpsEnd-opt.qEpsStart)*min(1,fe/budget);
if strcmp(opt.quotaPolicy,'random')
    ai=randi(sAux,numel(opt.quotaActions));
else
    if rand(sAux)<epsNow
        ai=randi(sAux,numel(opt.quotaActions));
    else
        [~,ai]=max(Q(s,:));
    end
end
qE=opt.quotaActions(ai);
end

function c=pickWeighted(w,sAux)
c=find(rand(sAux)<=cumsum(w),1);
if isempty(c), c=numel(w); end
end

function [c1,c2]=pickTwoCenters(ArcN,sAux)
pr=randi(sAux,ArcN,1,2); c1=pr(1); c2=pr(2);      % 两次 randi 同值同序
while c2==c1, c2=randi(sAux,ArcN); end
end

function [d,ni]=nearestIdx(y,Arc,ArcN)
[dd,nn]=min(sqrt(sum((Arc(1:ArcN,:)-y).^2,2))); d=dd; ni=nn;
end

function alloc=largestRemainder(w,K)
% 最大余数法：按权重把 K 个名额整数分配给各中心（和恰为 K）
q=K*w/sum(w);
alloc=floor(q);
rem=K-sum(alloc);
if rem>0
    [~,ord]=sort(q-alloc,'descend');
    for i=1:rem
        alloc(ord(mod(i-1,numel(ord))+1))=alloc(ord(mod(i-1,numel(ord))+1))+1;
    end
end
end

function [sel,nd]=selectCandidates(opt,qE,K,Y,src,par,ctr,Alpha,Arc,ArcN,ArcCred,span,sAux,gensSince)
%SELECTCANDIDATES  三种筛选规则（同一候选池）：
%   'random'  : 全池均匀随机取 K（S1）
%   'directed': G 路按到 alpha 距离升序；E 路按 credit 加权中心分配、
%               中心内取最近（S2 原版；SCREEN1 中被证伪，保留复现）
%   'strat'   : S2v2 —— 名额分层：E 占 round(qE*K)（credit 加权中心、
%               中心内随机）；剩余 G 名额按 g1Share 分给 G1（按 staleness
%               轮转的狼）与 G2（随机）；任何来源不足时用剩余池随机补齐。
nd=0; M=numel(src);
if strcmp(opt.screenPolicy,'random')
    sel=randperm(sAux,M,K)'; return
end
if strcmp(opt.screenPolicy,'spatial')
    Kc=max(0,min(K,round(opt.spatialConvFrac*K))); Kd=K-Kc;
    dA=sqrt(sum((Y-repmat(Alpha.Vector,M,1)).^2,2))/span; [~,ordA]=sort(dA,'ascend'); selC=ordA(1:Kc);
    rem=setdiff((1:M)',selC); selD=zeros(0,1);
    for qd=1:Kd
        if isempty(rem), break; end
        refs=[Y([selC;selD],:);Alpha.Vector]; dmin=inf(numel(rem),1);
        for rr=1:size(refs,1)
            dr=sqrt(sum((Y(rem,:)-repmat(refs(rr,:),numel(rem),1)).^2,2))/span; dmin=min(dmin,dr);
        end
        [~,mi]=max(dmin); selD(end+1,1)=rem(mi); rem(mi)=[];
    end
    sel=[selC;selD]; nd=nd+M+numel(selD);
    if numel(sel)<K
        rest=setdiff((1:M)',sel); sel=[sel;rest(randperm(sAux,numel(rest),K-numel(sel)))];
    end
    sel=sel(1:K); return
end
if strcmp(opt.screenPolicy,'directed')
    gIdx=find(src<=2); eIdx=find(src==3);
    K_e=min([round(qE*K),numel(eIdx),max(0,K-1)]);
    K_g=K-K_e;
    dg=sqrt(sum((Y(gIdx,:)-Alpha.Vector).^2,2))/span; nd=nd+numel(gIdx);
    [~,ordG]=sort(dg,'ascend');
    [selE,ndE]=eSample(eIdx,ctr,Arc,ArcCred,K_e,span,sAux,Y,true); nd=nd+ndE;
    sel=[gIdx(ordG(1:min(K_g,numel(gIdx)))); selE];
    if numel(sel)<K
        rest=setdiff((1:M)',sel); need=K-numel(sel);
        sel=[sel; rest(randperm(sAux,numel(rest),need))];
    end
    sel=sel(1:K); return
end
% ---- weighted：按 qE 映射来源权重做“不放回加权随机”采样（保留随机性、
%      只改变期望 E 份额；qE=池比例时权重全 1，退化为均匀随机） ----
if strcmp(opt.screenPolicy,'weighted')
    eIdx=find(src==3); oIdx=find(src~=3);
    nE=numel(eIdx); nO=numel(oIdx);
    q=min(max(qE,1e-4),1-1e-4);
    wE=quotaToWeight(qE);   % 经固定种子蒙特卡洛标定（tests/diag_calibrate_weights.m）
    w=ones(M,1); w(eIdx)=wE;
    keys=rand(sAux,M,1).^(1./w);
    [~,ord]=sort(keys,'descend');
    sel=ord(1:K);
    return
end
% ---- strat ----
eIdx=find(src==3); g1=find(src==1); g2=find(src==2);
K_e=min([round(qE*K),numel(eIdx)]);
K_g=K-K_e;
a1=min([N_wolvesPar(par), round(K_g*opt.g1Share), numel(g1)]);
% G1：按 gensSince 轮转选择（越大越优先；并列取小索引）
wolves=par(g1);
age=gensSince(wolves);
if strcmp(opt.stratG1,'random')
    pick=g1(randperm(sAux,numel(g1),min(a1,numel(g1))));
else
    [~,ord]=sortrows([-age,(1:numel(g1))']);
    pick=g1(ord(1:min(a1,numel(g1))));
end
if ~isfield(opt,'debugSel') || opt.debugSel
    fprintf('[sel-debug] stratG1=%s a1=%d ageMax=%d pick(1:5)=%s\n',opt.stratG1,a1,max(age),mat2str(pick(1:min(5,numel(pick)))'));
end
sel=pick(:);
% G2：随机
a2=min(K_g-numel(sel),numel(g2));
if a2>0, sel=[sel; g2(randperm(sAux,numel(g2),a2))]; end
% E：credit 加权中心分配 + 中心内随机（stratE='random' 时全 E 池均匀随机）
if K_e>0
    if strcmp(opt.stratE,'random')
        sel=[sel; eIdx(randperm(sAux,numel(eIdx),K_e))];
    else
        [selE,ndE]=eSample(eIdx,ctr,Arc,ArcCred,K_e,span,sAux,Y,false); nd=nd+ndE;
        sel=[sel; selE];
    end
end
if numel(sel)<K
    rest=setdiff((1:M)',sel); need=K-numel(sel);
    sel=[sel; rest(randperm(sAux,numel(rest),need))];
end
sel=sel(1:K);
end

function [selE,nd]=eSample(eIdx,ctr,Arc,ArcCred,K_e,span,sAux,Y,nearFirst)
% E 路：按中心 credit 权重（最大余数）分配名额；
% nearFirst=true 时中心内取离中心最近者（S2 原版语义，用于复现），
% false 时中心内均匀随机（S2v2）。
nd=0; selE=zeros(0,1);
if K_e<=0 || isempty(eIdx), return; end
cList=unique(ctr(eIdx)); cList=cList(cList>0);
if isempty(cList)
    selE=eIdx(randperm(sAux,numel(eIdx),K_e)); return
end
wts=1+ArcCred(cList);
nAlloc=largestRemainder(wts,K_e);
for ci=1:numel(cList)
    if nAlloc(ci)<=0, continue; end
    c=cList(ci);
    pos=find(ctr(eIdx)==c);
    if isempty(pos), continue; end
    if nearFirst
        dc=sqrt(sum((Y(eIdx(pos),:)-Arc(c,:)).^2,2))/span;
        nd=nd+numel(pos);
        [~,ord]=sort(dc,'ascend');
        take=pos(ord(1:min(nAlloc(ci),numel(pos))));
    else
        take=pos(randperm(sAux,numel(pos),min(nAlloc(ci),numel(pos))));
    end
    selE=[selE; eIdx(take)]; %#ok<AGROW>
end
if numel(selE)>K_e, selE=selE(1:K_e); end
end

function n=N_wolvesPar(par)
n=max(par);  % 池内狼索引最大值即 N（G1 覆盖全部狼）
end
function c=sAux2less(p,sAux)
c=rand(sAux)<p;
end

function wE=quotaToWeight(qE)
%QUOTATOWEIGHT  配额份额 -> 采样权重（蒙特卡洛标定：nE=38, nO=62, K=50）
%   标定脚本：tests/diag_calibrate_weights.m（固定种子 20261016）。
%   实测：wE=0.431226 -> E份额 0.2500；2.072659 -> 0.4998；20.535322 -> 0.7501。
qs=[0.25 0.50 0.75]; ws=[0.431226 2.072659 20.535322];
if qE<=qs(1), wE=ws(1); return; end
if qE>=qs(end), wE=ws(end); return; end
wE=exp(interp1(qs,log(ws),qE,'linear'));
end

function sig=shellSigma(succ,span,D)
if numel(succ)>=5
    L=median(succ);
else
    L=0.05*span;
end
L=max(L,0.01*span);
sig=L*sqrt(3/D);
end

function [A,B,Dl]=insertLeader(A,B,Dl,x,v)
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end













function y=gwoMove(aA,A,B,Dl,xw,lb,ub)
%标准 GWO 领导聚合移动（与 G1 同公式；用于被关闭槽位的填补候选）
D=numel(lb);
R6=rand(1,6*D);                            % 与六次 rand(1,D) 完全同值同序
A1=2*aA*R6(1:D)-aA;         C1=2*R6(D+1:2*D);
A2=2*aA*R6(2*D+1:3*D)-aA;   C2=2*R6(3*D+1:4*D);
A3=2*aA*R6(4*D+1:5*D)-aA;   C3=2*R6(5*D+1:6*D);
X1=A.Vector-A1.*abs(C1.*A.Vector-xw);
X2=B.Vector -A2.*abs(C2.*B.Vector -xw);
X3=Dl.Vector-A3.*abs(C3.*Dl.Vector-xw);
y=min(max((X1+X2+X3)/3,lb),ub);
end





