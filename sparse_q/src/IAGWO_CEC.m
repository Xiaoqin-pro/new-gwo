function [Best,T,info]=IAGWO_CEC(f,state,~,N,seed)
%IAGWO_CEC  IAGWO 复现（Yu, Xu, Liang, Qiu, Bao & Tang, Artificial Intelligence
%   Review 2024, 57:277, doi:10.1007/s10462-024-10821-3；开放获取全文；
%   GitHub 无官方代码 -> 按论文 Eq.(8)-(12) 与 Algorithm 2 逐条实现）
%
%   三个机制（论文 3.2 节，全部保留）：
%     (1) PSO 搜索机制（Eq.8）
%           v_i <- v_i + phi*(Xbest - X_i) + phi*(Xselfbest - X_i)
%           X_i <- X_i + v_i,            phi ~ U[0,1]
%         Xbest = alpha；Xselfbest = 个体历史最优；v 初值 ~ U[-20,20]（Table 1）
%     (2) IMF 惯性权重（Eq.9-10）
%           omega(t) = a*exp(-b*exp(-c*t)) + d,  [a b c d] = [0.6 0.02 0.05 0.3]
%           X1 = Xa - omega*A1.*Da, X2 = Xb - omega*A2.*Db, X3 = Xd - omega*A3.*Dd
%         omega 由 0.9 单调降到 0.3（Fig.3）：前中期强领导引导，后期放开自主搜索
%     (3) Sigmoid 自适应更新（Eq.11-12）
%           phi_i = 1/(1+(exp(-f_i/f_ave))^theta),  theta = 0.5
%           Y_i <- Y_i * phi_i
%         适应度好（f_i/f_ave 小）的个体只做小幅修正，差个体接受完整 GWO 步长；
%         按公式 phi_i in (0.5, 1)
%
%   与论文的差异（接口 / 计费 / 时间轴 / 基准适配，逐条记录于 docs/150）：
%     * 初始种群由实验框架给定（与全部算法同一初始池）
%     * 时间轴一律用真实 FE 进度 prog=fe/budget（论文用迭代号），与全部算法等 FE
%     * Algorithm 2 的第 10-20 行顺序有歧义（"Calculate New Position" 之后又
%       "Update X1,X2,X3 with IMF inertia weight"、"Update X(t+1)"）。本实现取如下
%       一致顺序，且每个候选生成后立即真实评价（AGENTS 第三节硬约束）：
%         a) PSO 速度/位置更新 -> 真实评价（N 次）
%         b) omega 加权的三领导目标 Xg -> 位移 (Xg-X_i) 乘 phi_i -> 真实评价（N 次）
%       每代 2N 次真实评价，FE 精确等于预算
%     * phi 每狼每代只抽一个随机数（论文只写 "phi is a random number"，未说明两项
%       是否独立），Eq.8 的两项共用该 phi
%     * **Eq.11 的比值基准**：论文用 f_i/f_ave 的绝对量值。CEC2017 目标含 100*i 平移
%       偏移，直接用原始量值会使 f_i/f_ave≈1、phi 退化为常数（0.62 左右），Sigmoid
%       机制完全失效。默认 state.iagwoPhiMode='shift'（先减当前最优再取比值，即
%       (f_i-f_best)/(f_ave-f_best)），使 phi 与目标的平移无关、机制按论文意图生效；
%       'raw' 保留字面公式作敏感性对照。两者都在 info 中记录 phi 的离散度
%     * f_ave 用当前已验证适应度均值；若 (f_ave-f_best)<=0 或非有限，该代 phi 置 1
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
V=-20+40*rand(N,D);                     % Table 1: vrand(t) in [-20,20]
phiMode='shift';
if isfield(state,'iagwoPhiMode') && ~isempty(state.iagwoPhiMode), phiMode=char(state.iagwoPhiMode); end
% ---- 初始评价 ----
fit=inf(N,1); pbest=X; pbestF=inf(N,1); fe=0; gb=inf; bVec=X(1,:);
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
for i=1:N
    v=f(X(i,:)); fe=fe+1; fit(i)=v; pbestF(i)=v;
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,X(i,:),v);
end
phiLog=zeros(0,1); rounds=0;
while fe<budget
    rounds=rounds+1;
    prog=fe/budget;
    % ---- (1) PSO 搜索机制（Eq.8） ----
    for i=1:N
        if fe>=budget, break; end
        phi=rand();
        V(i,:)=V(i,:)+phi*(Alpha.Vector-X(i,:))+phi*(pbest(i,:)-X(i,:));
        Xn=min(max(X(i,:)+V(i,:),lb),ub);
        X(i,:)=Xn;
        v=f(Xn); fe=fe+1; fit(i)=v;
        if v<pbestF(i), pbestF(i)=v; pbest(i,:)=Xn; end
        if v<gb, gb=v; bVec=Xn; end
        T(fe)=gb;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,Xn,v);
    end
    if fe>=budget, break; end
    % ---- (2)+(3) IMF 加权三领导目标 + Sigmoid 自适应位移 ----
    omega=0.6*exp(-0.02*exp(-0.05*prog))+0.3;
    a=2*(1-prog);
    fbest=min(fit); fave=mean(fit);
    for i=1:N
        if fe>=budget, break; end
        Da=abs(2*rand(1,D).*Alpha.Vector-X(i,:)); A1=2*a*rand(1,D)-a;
        Db=abs(2*rand(1,D).*Beta.Vector -X(i,:)); A2=2*a*rand(1,D)-a;
        Dd=abs(2*rand(1,D).*Delta.Vector-X(i,:)); A3=2*a*rand(1,D)-a;
        Xg=(Alpha.Vector-omega*A1.*Da + Beta.Vector-omega*A2.*Db + Delta.Vector-omega*A3.*Dd)/3;
        if strcmp(phiMode,'raw')
            num=fit(i); den=fave;
        else
            num=fit(i)-fbest; den=fave-fbest;
        end
        if isfinite(den) && den>0 && isfinite(num)
            phiI=1/(1+(exp(-num/den))^0.5);
        else
            phiI=1;
        end
        phiLog(end+1,1)=phiI; %#ok<AGROW>
        Xn=min(max(X(i,:)+phiI*(Xg-X(i,:)),lb),ub);
        X(i,:)=Xn;
        v=f(Xn); fe=fe+1; fit(i)=v;
        if v<pbestF(i), pbestF(i)=v; pbest(i,:)=Xn; end
        if v<gb, gb=v; bVec=Xn; end
        T(fe)=gb;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,Xn,v);
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','IAGWO-CEC','Rounds',rounds, ...
    'PhiMode',phiMode,'PhiMean',mean(phiLog),'PhiStd',std(phiLog), ...
    'Source','paper-reconstruction');
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
