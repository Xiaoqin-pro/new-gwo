function [Best,T,info]=ANGWO(f,state,~,N,seed)
%ANGWO  Adaptive Novelty-Guided Grey Wolf Optimizer (working name, NEW_GWO_2026).
%
%   [Best,T,info]=ANGWO(f,state,[],N,seed)
%
%   一个机制轻量、无 GNN 的灰狼群变体：保留标准 GWO 的搜索骨架，只在
%   "哪只狼该探索、探索到哪里" 这一个设计变量上做两个可分离的改动。
%
%   ---- 模块 E：探索勤务 + 新颖度过滤的局部侦察 ----
%   每个世代把 pbest 排名后 50% 中"最久没有改善"的少量狼指派为侦察狼
%   (rover)；侦察狼不走标准 GWO 方程，而是以自身位置为中心、以最近真实
%   成功步长的中位数为尺度做局部采样，并在候选池中挑选对"已评价位置档案"
%   最近邻距离最大的候选。探索名额占比 theta 由真实改善信用自适应：
%     theta <- clip(theta + eta*(r_rover - r_exploit), [thetaLo,thetaHi])
%   其中 r 为对应角色"被记功的真实评价"比例（记功 = 刷新自身 pbest 或
%   刷新当前最优）。
%
%   ---- 模块 S：停滞触发的全局新颖度重部署 ----
%   当连续 (stallWindow) 次真实评价未刷新全局最优时，进入救援窗口：每代
%   把最久无改善、且 fitness 排名靠后的 rescueQ 只狼重新部署到"对整个
%   档案最不明显"的位置（在候选池中取最近邻距离最大者），救援持续
%   rescueLength 代，之后冷却 stallWindow 次评价。绝不重部署排名前 50%
%   的狼（防止破坏正在收敛的函数，如 F3/F18）。
%
%   ---- 选项（state 字段，均可省略） ----
%     exploreMode   'off' | 'fixed' | 'random' | 'adaptive'   (默认 'off')
%     exploreShare  theta 初值/固定值                          (默认 0.10)
%     thetaLo/thetaHi/eta 自适应边界与步长                     (0.02/0.30/2.0)
%     roverDest     'novelty' | 'random'                       (默认 'novelty')
%     roverCenter   'self' | 'alpha'（侦察采样中心）             (默认 'self')
%     roverK        侦察候选池大小                             (默认 8)
%     recoveryMode  'off' | 'stagnation' | 'periodic'          (默认 'off')
%     recoveryDest  'novelty' | 'random'                       (默认 'novelty')
%     rescueK       救援候选池大小                             (默认 16)
%     rescueQ       每次救援重部署的狼数                       (默认 0.2N)
%     rescueLength  每次救援持续代数                           (默认 2)
%     stallWindow   停滞判定窗口（真实 FE）                    (默认 1% budget)
%     archiveSize   新颖度档案容量                             (默认 200)
%     probe         EvalProbe 句柄（由 runner 注入；缺失时自行创建）
%
%   随机性分离：搜索主流程只用 rng(seed,'twister') 的基流；模块的所有
%   随机数（候选池、重部署、随机配额）都从 RandStream(seed+7919) 抽取，
%   因此把两个模块开关全关掉时，本文件与 GWO.m 逐位一致
%   （tests/test_angwo_equivalence.m 强制）。
%
%   真实评价预算：与 GWO 相同，每代每只狼恰好 1 次评价，初始化计入预算，
%   全流程不产生任何额外真实评价。

% ==================== 选项与前置检查 ====================
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch: state holds %d rows, N=%d.',N0,N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D,'Bound vectors must match D=%d.',D);
assert(budget>=N && budget==floor(budget),'Budget must be integer >= N.');
assert(all(isfinite(X),'all') && all(X>=lb & X<=ub,'all'), ...
    'Initial population must be finite and inside the bounds.');

opt=angwoOptions(state,budget,N);
exploreOn=~strcmp(opt.exploreMode,'off');
recoverOn=~strcmp(opt.recoveryMode,'off');
aux=RandStream('mt19937ar','Seed',seed+7919);

% 探针：runner 注入则复用（评价已由它包裹），否则自行创建并接管评价入口
probe=[];
fEval=f;
if exploreOn || recoverOn
    if isfield(state,'probe') && ~isempty(state.probe)
        probe=state.probe;
    else
        probe=EvalProbe(lb,ub,budget,seed+51,5,opt.archiveSize);
        fEval=@(x)probeEval(probe,f,x);
    end
end

rng(seed,'twister');
clockStart=tic;

% ==================== 初始化（与 GWO.m 相同语义） ====================
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D));
Beta=Alpha; Delta=Alpha;
pbestV=inf(N,1); lastImpFE=zeros(N,1);
fe=0;
for i=1:N
    v=fEval(X(i,:));
    fe=fe+1;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,X(i,:),v);
    T(fe)=Alpha.Cost;
    pbestV(i)=v; lastImpFE(i)=fe;
end
lastGImproveFE=fe;
span=norm(ub-lb);                    % 搜索空间对角线（全部壳采样/新颖度的尺度）

% ==================== 模块状态 ====================
EM=zeros(opt.eliteMemSize,D); EMv=inf(opt.eliteMemSize,1); EMn=0;   % 精英记忆（已验证位置）
keepEM=strcmp(opt.recoveryDest,'elite');
theta=opt.exploreShare;
succCap=25; succ=zeros(0,1); succPtr=0;
rescueActive=false; rescueStepsLeft=0; rescueCooldownUntil=0;
nextPeriodicFE=opt.stallWindow;
winStart=fe+1;
winEnd=fe+opt.stallWindow;
winNExp=0; winNRov=0; winNRes=0; winImpExp=0; winImpRov=0;
thetaTrace=zeros(0,2);
roleTrace=zeros(0,5);
nCandidateGenerated=0;
rounds=0;

% ==================== 主循环 ====================
while fe<budget
    rounds=rounds+1;
    a=2-2*(fe/budget);

    % ---- 角色指派（确定性，无随机数） ----
    age=fe-lastImpFE;
    [~,pord]=sort(pbestV,'ascend');              % 1 = best pbest
    ranks=zeros(N,1); ranks(pord)=1:N;
    eligible=ranks>N/2;                          % 只允许后半段当侦察/救援
    eIdx=find(eligible);
    [~,as]=sortrows([-age(eIdx), -pbestV(eIdx), eIdx]); %#ok<ASGLU>
    prio=eIdx(as);                               % 最久无改善者优先
    roles=ones(N,1);                             % 1=exploit 2=rover 3=rescue
    nRes=0;

    if recoverOn
        if strcmp(opt.recoveryMode,'periodic')
            if fe>=nextPeriodicFE
                if ~rescueActive
                    rescueActive=true; rescueStepsLeft=opt.rescueLength;
                end
                while fe>=nextPeriodicFE, nextPeriodicFE=nextPeriodicFE+opt.stallWindow; end
            end
        else % stagnation
            if ~rescueActive && (fe-lastGImproveFE)>=opt.stallWindow && fe>=rescueCooldownUntil
                rescueActive=true; rescueStepsLeft=opt.rescueLength;
            end
        end
        if rescueActive
            nRes=min(opt.rescueQ,numel(prio));
            roles(prio(1:nRes))=3;
            rescueStepsLeft=rescueStepsLeft-1;
            if rescueStepsLeft<=0
                rescueActive=false;
                if strcmp(opt.recoveryMode,'stagnation')
                    rescueCooldownUntil=fe+opt.stallWindow;
                end
            end
        end
    end

    nRov=0;
    if exploreOn
        avail=prio(~ismember(prio,prio(1:nRes)));
        nRov=min(max(1,round(theta*N)),numel(avail));
        if nRov>0, roles(avail(1:nRov))=2; end
    end

    % ---- 逐狼移动与评价 ----
    for i=1:N
        if fe>=budget, break; end
        xold=X(i,:);
        switch roles(i)
            case 2 % ---- 侦察狼：以"最近真实成功步长"为尺度的局部侦察 ----
                sig=shellSigma(succ,lb,ub,D);
                if strcmp(opt.roverCenter,'alpha')
                    center=Alpha.Vector;      % 围绕当前最优的信任域采样
                else
                    center=xold;              % 围绕该狼自身位置采样
                end
                if strcmp(opt.roverDest,'random')
                    cand=center+sig*(2*rand(aux,1,D)-1);
                    xn=min(max(cand,lb),ub);
                    nCandidateGenerated=nCandidateGenerated+1;
                else
                    K=opt.roverK;
                    cands=center+sig*(2*rand(aux,K,D)-1);
                    cands=min(max(cands,lb),ub);
                    nv=probe.noveltyOfMany(cands);
                    [~,bi]=max(nv);
                    xn=cands(bi,:);
                    nCandidateGenerated=nCandidateGenerated+K;
                end
            case 3 % ---- 救援狼：停滞触发的重部署（四种目标规则） ----
                switch opt.recoveryDest
                    case 'random'      % 全空间均匀随机（对照）
                        xn=lb+(ub-lb).*rand(aux,1,D);
                        nCandidateGenerated=nCandidateGenerated+1;
                    case 'elite'       % 已验证精英记忆的壳内采样
                        sig=shellSigma(succ,lb,ub,D);
                        r=randi(aux,EMn);
                        xn=EM(r,:)+opt.rescueScaleMult*sig*(2*rand(aux,1,D)-1);
                        xn=min(max(xn,lb),ub);
                        nCandidateGenerated=nCandidateGenerated+1;
                    case 'alphaShell'  % 围绕当前最优的"信任域扩张"
                        sig=shellSigma(succ,lb,ub,D);
                        xn=Alpha.Vector+opt.rescueScaleMult*sig*(2*rand(aux,1,D)-1);
                        xn=min(max(xn,lb),ub);
                        nCandidateGenerated=nCandidateGenerated+1;
                    otherwise          % 全局新颖度池（对照：取最不明显点）
                        K=opt.rescueK;
                        cands=lb+(ub-lb).*rand(aux,K,D);
                        nv=probe.noveltyOfMany(cands);
                        [~,bi]=max(nv);
                        xn=cands(bi,:);
                        nCandidateGenerated=nCandidateGenerated+K;
                end
            otherwise % ---- 标准 GWO 方程（与 GWO.m 完全相同的抽样顺序） ----
                A1=2*a*rand(1,D)-a;  C1=2*rand(1,D);
                A2=2*a*rand(1,D)-a;  C2=2*rand(1,D);
                A3=2*a*rand(1,D)-a;  C3=2*rand(1,D);
                X1=Alpha.Vector-A1.*abs(C1.*Alpha.Vector-xold);
                X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -xold);
                X3=Delta.Vector-A3.*abs(C3.*Delta.Vector -xold);
                xn=(X1+X2+X3)/3;
                xn=min(max(xn,lb),ub);
        end
        X(i,:)=xn;
        v=fEval(xn);
        fe=fe+1;
        gbImp=v<Alpha.Cost;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,xn,v);
        T(fe)=Alpha.Cost;

        improved=v<pbestV(i);
        if improved
            if numel(succ)<succCap
                succ(end+1,1)=norm(xn-xold); %#ok<AGROW>
            else
                succPtr=mod(succPtr,succCap)+1;
                succ(succPtr)=norm(xn-xold);
            end
            pbestV(i)=v; lastImpFE(i)=fe;
        end
        if gbImp, lastGImproveFE=fe; end

        % ---- 精英记忆维护（仅在 recoveryDest='elite' 时启用） ----
        if keepEM
            if EMn<opt.eliteMemSize
                EMn=EMn+1; EM(EMn,:)=xn; EMv(EMn)=v;
            elseif v<max(EMv(1:EMn))
                dmin=min(sqrt(sum((EM(1:EMn,:)-xn).^2,2)));
                if dmin>1e-3*span
                    [~,wi]=max(EMv(1:EMn));
                    EM(wi,:)=xn; EMv(wi)=v;
                end
            end
        end

        % ---- 真实改善信用（分角色） ----
        credited=improved || gbImp;
        if roles(i)==2
            winNRov=winNRov+1; winImpRov=winImpRov+credited;
        elseif roles(i)==3
            winNRes=winNRes+1;
        else
            winNExp=winNExp+1; winImpExp=winImpExp+credited;
        end

        % ---- 信用窗口结算（random 模式在此重新抽 theta；adaptive 在此更新） ----
        if fe>=winEnd
            if strcmp(opt.exploreMode,'random')
                theta=opt.thetaLo+(opt.thetaHi-opt.thetaLo)*rand(aux);
            end
            if strcmp(opt.exploreMode,'adaptive') && winNRov>=10 && winNExp>=5
                rR=winImpRov/winNRov; rE=winImpExp/winNExp;
                theta=min(max(theta+opt.eta*(rR-rE),opt.thetaLo),opt.thetaHi);
            end
            thetaTrace(end+1,:)=[fe,theta]; %#ok<AGROW>
            roleTrace(end+1,:)=[winStart,winNExp,winNRov,winNRes,theta]; %#ok<AGROW>
            winStart=fe+1; winEnd=fe+opt.stallWindow;
            winNExp=0; winNRov=0; winNRes=0; winImpExp=0; winImpRov=0;
        end
    end
end

% ==================== 输出 ====================
Best.Cost=Alpha.Cost;
Best.Vector=Alpha.Vector;
info.Evaluations=fe;
info.Rounds=rounds;
info.MeanEvalsPerRound=fe/max(rounds,1);
info.WallClock=toc(clockStart);
info.Algorithm=sprintf('ANGWO(%s,%s)',opt.exploreMode,opt.recoveryMode);
info.ThetaTrace=thetaTrace;
info.RoleTrace=roleTrace;
info.NCandidateGenerated=nCandidateGenerated;
info.LastGImproveFE=lastGImproveFE;
info.EliteMemoryCount=EMn;
if ~isempty(probe)
    info.Probe=probe;
end
end

% ==================== 辅助函数 ====================
function opt=angwoOptions(state,budget,N)
opt=struct('exploreMode','off','exploreShare',0.10, ...
    'thetaLo',0.02,'thetaHi',0.30,'eta',2.0, ...
    'roverDest','novelty','roverK',8,'roverCenter','self', ...
    'recoveryMode','off','recoveryDest','novelty','rescueK',16,'rescueScaleMult',3, ...
    'rescueQ',max(1,round(0.2*N)),'rescueLength',2,'eliteMemSize',32, ...
    'stallWindow',max(50,round(0.01*budget)),'archiveSize',200);
fn=fieldnames(state);
for k=1:numel(fn)
    % NOTE: job struct arrays pad missing fields with []; ignoring empty
    % values is REQUIRED, otherwise a padded [] silently overrides a default
    % (this exact bug invalidated the first rd1 batch - see registry.csv).
    if isfield(opt,fn{k}) && ~isempty(state.(fn{k}))
        opt.(fn{k})=state.(fn{k});
    end
end
end

function sig=shellSigma(succ,lb,ub,D)
%SHELLSIGMA  壳采样尺度：最近真实成功步长中位数（下限 1% 对角线）
span=norm(ub-lb);
if numel(succ)>=5
    L=median(succ);
else
    L=0.05*span;
end
L=max(L,0.01*span);
sig=L*sqrt(3/D);
end

function v=probeEval(probe,f,x)
v=probe.evaluate(f,x);
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




