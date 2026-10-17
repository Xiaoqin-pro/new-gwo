function [Best,T,info]=DMSGWO_CEC(f,state,~,N,seed)
%DMSGWO_CEC  DMSGWO 论文重建版（Wang et al., Scientific Reports 2026,
%   doi:10.1038/s41598-026-54428-w；官方源码 wangyoki/DMSGWO @a6229f5）
%
%  官方源码的“开发组循环”为空（仅剩 `%%` 占位），无法直接运行。
%  本实现 = 官方代码骨架 + 论文公式补全（标注：paper-based reconstruction）：
%    Eq.(8)  Xgwo = (X1+X2+X3)/3  三领导狼 GWO 目标（逐维 A/C；非线性因子 a）
%    Eq.(12) phi  = (f_i / f_avg)^3
%    Eq.(13) w    = 0.5 + 0.5cos(pi*t/T)     （t/T 以真实 FE 进度 fe/budget 计）
%    Eq.(14) X(t+1) = (1-w)Xgwo + w*Xgwo.*phi（逐维；贪心接受）
%  其余骨架与官方源码一致：
%    * 每轮开始按当前种群刷新领导（缓存去重；作者源码的重复 objf 调用不计费重复）；
%    * 探索组逐维 Lévy/随机差分候选（Eq.(10)(11)，贪心接受）；
%    * 开发组每狼一个候选（Eq.(14)）；
%    * 分组规模动态调整（改进→n1-1；连续>=3 代无改善→n1+1）。
%  FE 计费修复：同一位置只做一次真实评价；T 与 Best 为真实 best-so-far 口径
%  （作者源码 Alpha 仅在轮首刷新，末轮改进不回读——本实现按公平口径报告最好值，
%  领导引导状态仍按轮首规则，属报告口径修正，见 docs/14）。
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
Positions=X; fit=inf(N,1); fe=0; gb=inf; bVec=X(1,:);
for i=1:N
    v=f(Positions(i,:)); fe=fe+1;
    if v<gb, gb=v; bVec=Positions(i,:); end
    T(fe)=gb; fit(i)=v;
    [Alpha,Beta,Delta]=updAuthor(Alpha,Beta,Delta,Positions(i,:),v);
end
n1=round(N*0.5); n2=N-n1; noImp=0; prevBest=inf; it=0;
while fe<budget
    it=it+1;
    prog=fe/budget;
    % ---- 轮首：按当前种群刷新领导（缓存值=真实评价，不重复计费） ----
    for i=1:N
        [Alpha,Beta,Delta]=updAuthor(Alpha,Beta,Delta,Positions(i,:),fit(i));
    end
    a=2/log10(2)*log10(2-prog^3);
    favg=mean(fit);
    % ---- 探索组（Eq.(10)(11)） ----
    for i=1:n1
        if fe>=budget, break; end
        for j=1:D
            if fe>=budget, break; end
            if rand()>0.5
                newpop=Positions(i,:)+rand()*(Positions(i,j)-Alpha.Vector(j)).*levyVec(D);
            else
                ri=randperm(N,2);
                newpop=Positions(i,:)+rand()*(Positions(ri(1),j)-Positions(ri(2),j));
            end
            newpop=min(max(newpop,lb),ub);
            v=f(newpop); fe=fe+1;
            if v<gb, gb=v; bVec=newpop; end
            T(fe)=gb;
            if v<fit(i), fit(i)=v; Positions(i,:)=newpop; end
        end
    end
    % ---- 开发组（Eq.(8)(12)(13)(14)） ----
    w=0.5+0.5*cos(pi*prog);
    for i=n1+1:N
        if fe>=budget, break; end
        xi=Positions(i,:);
        A1=2*a*rand(1,D)-a; C1=2*rand(1,D);
        A2=2*a*rand(1,D)-a; C2=2*rand(1,D);
        A3=2*a*rand(1,D)-a; C3=2*rand(1,D);
        X1=Alpha.Vector-A1.*abs(C1.*Alpha.Vector-xi);
        X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -xi);
        X3=Delta.Vector-A3.*abs(C3.*Delta.Vector-xi);
        Xgwo=(X1+X2+X3)/3;
        phi=(fit(i)/favg)^3;
        newpop=(1-w)*Xgwo + w*Xgwo.*phi;
        newpop=min(max(newpop,lb),ub);
        v=f(newpop); fe=fe+1;
        if v<gb, gb=v; bVec=newpop; end
        T(fe)=gb;
        if v<fit(i), fit(i)=v; Positions(i,:)=newpop; end
    end
    % ---- 分组规模动态调整（官方源码逻辑） ----
    if Alpha.Cost<prevBest
        noImp=0;
        if n1>1 && n2<N-1, n1=n1-1; n2=n2+1; end
    else
        noImp=noImp+1;
        if noImp>=3
            if n1<N-1 && n2>1, n1=n1+1; n2=n2-1; end
        else
            if n1>1 && n2<N-1, n1=n1-1; n2=n2+1; end
        end
    end
    prevBest=Alpha.Cost;
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','DMSGWO-CEC','Rounds',it,'Mode','recon');
end

% ==================== 辅助函数 ====================
function [A,B,Dl]=updAuthor(A,B,Dl,x,v)
%官方源码的领导更新顺序（字面移植，含其比较语义）
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
end
if v>A.Cost && v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
end
if v>A.Cost && v>B.Cost && v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end

function L=levyVec(D)
beta=1.5;
sigma=(gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
u=randn(1,D)*sigma;
v=randn(1,D);
L=u./abs(v).^(1/beta);
end
