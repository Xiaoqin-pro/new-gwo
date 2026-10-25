function [Best,T,info]=DEElimGWO_CEC(f,state,~,N,seed)
%DE-ELIM GWO -- **DROPPED 2026-10-25 (user decision)**
%   该基线已从对比集中移除：Corrected GWO 因原文公式不可得（论文站点 captcha、
%   FEX 需登录）只能按一句话机制描述重建，证据强度不足；DE-Elim GWO 因 Eq.18
%   在正文与公式中自相矛盾。文件保留为存档，不注册到 runner_sgwo、不进入任何
%   正式批次。替代基线见 IAGWO_CEC.m（2024, AI Review, 公式完整）。
%DEElimGWO_CEC  DE-Elimination GWO 复现（Wang & Li, Scientific Reports 2019,
%   doi:10.1038/s41598-019-43546-3；无官方代码 -> 按论文公式逐条实现）
%
%   机制（论文 Eq.5-18，全部保留）：
%     (1) 标准 GWO 三领导聚合（Eq.5-11，逐维 A/C）
%     (2) DE 进化算子（Eq.13-17）：变异用三个领导而非随机个体
%           V = alpha + F*(beta - delta)                      (Eq.14)
%           F = fmin + (fmax-fmin)*(Max_iter-(iter-1))/Max_iter (Eq.15)
%           U_j = V_j if rand_j<=CR or j==jrand, else X_ij    (Eq.16)
%           贪心选择 X_i <- U_i if f(U_i)<f(X_i)              (Eq.17)
%     (3) SOF 淘汰（Eq.18）：排序后淘汰 R 个最差个体并随机生成 R 个新个体
%   原文参数：fmin=0.25, fmax=1.5, CR=0.7, epsilon=5（Table 2）。
%
%   与论文的差异（接口 / 计费 / 时间轴，逐条）：
%     * 初始种群由实验框架给定（与全部算法同一初始池）
%     * Max_iter 由真实 FE 预算折算：每代消耗 2N+R 次真实评价（GWO 更新后 N 次、
%       DE 试验向量 N 次、淘汰补充 R 次），取 Max_iter=floor((budget-N)/(2N+Rbar))，
%       Rbar 为 Eq.18 区间中点；F 的时间轴用已用代数/ Max_iter
%     * Eq.18 的区间在原文正文（"between n/(2*eps) and n/eps"）与公式
%       （"R=[n/eps, n/(0.75*eps)]"）不一致；默认按公式实现（deElimRMode='eq18'），
%       正文版本作为敏感性开关（'prose'）
%     * 预算边界处逐次评价，绝不超支；被淘汰新个体的位置在进入下一次排序前必然
%       已被真实评价
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
fmin=0.25; fmax=1.5; CR=0.7; epsR=5;
rMode='eq18';
if isfield(state,'deElimRMode') && ~isempty(state.deElimRMode), rMode=char(state.deElimRMode); end
switch rMode
    case 'prose'
        rLo=N/(2*epsR); rHi=N/epsR;
    otherwise
        rLo=N/epsR;     rHi=N/(0.75*epsR);
end
Rbar=round((rLo+rHi)/2);
maxIter=max(1,floor((budget-N)/(2*N+Rbar)));
fit=inf(N,1); fe=0; gb=inf; bVec=X(1,:);
for i=1:N
    v=f(X(i,:)); fe=fe+1; fit(i)=v;
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb;
end
rounds=0;
while fe<budget
    rounds=rounds+1;
    [~,ord]=sort(fit,'ascend');
    Alpha=X(ord(1),:); Beta=X(ord(2),:); Delta=X(ord(3),:);
    a=2-2*(rounds-1)/maxIter;
    % ---- (1) GWO 位置更新（Eq.5-11） ----
    for i=1:N
        r1=rand(1,D); r2=rand(1,D); A1=2*a*r1-a; C1=2*r2;
        X1=Alpha-A1.*abs(C1.*Alpha-X(i,:));
        r1=rand(1,D); r2=rand(1,D); A2=2*a*r1-a; C2=2*r2;
        X2=Beta -A2.*abs(C2.*Beta -X(i,:));
        r1=rand(1,D); r2=rand(1,D); A3=2*a*r1-a; C3=2*r2;
        X3=Delta-A3.*abs(C3.*Delta-X(i,:));
        X(i,:)=min(max((X1+X2+X3)/3,lb),ub);
    end
    for i=1:N
        if fe>=budget, break; end
        v=f(X(i,:)); fe=fe+1; fit(i)=v;
        if v<gb, gb=v; bVec=X(i,:); end
        T(fe)=gb;
    end
    if fe>=budget, break; end
    % ---- (2) DE 进化（Eq.14-17） ----
    F=fmin+(fmax-fmin)*(maxIter-(rounds-1))/maxIter;
    V=Alpha+F*(Beta-Delta);
    for i=1:N
        if fe>=budget, break; end
        jr=randi(D);
        mask=rand(1,D)<=CR; mask(jr)=true;
        U=V; U(~mask)=X(i,~mask);
        U=min(max(U,lb),ub);
        v=f(U); fe=fe+1;
        if v<gb, gb=v; bVec=U; end
        T(fe)=gb;
        if v<fit(i)          % Eq.17 贪心
            X(i,:)=U; fit(i)=v;
        end
    end
    if fe>=budget, break; end
    % ---- (3) SOF 淘汰 + 随机补充（Eq.18） ----
    R=randi([max(1,floor(rLo)), max(1,ceil(rHi))]);
    R=min(R,N-3);
    if R>0
        [~,ord]=sort(fit,'ascend');
        keep=sort(ord(1:N-R));
        X=X(keep,:); fit=fit(keep); N=N-R;
        Xn=lb+(ub-lb).*rand(R,D);
        X=[X;Xn]; fit=[fit;inf(R,1)]; N=N+R;
        for i=N-R+1:N
            if fe>=budget, break; end
            v=f(X(i,:)); fe=fe+1; fit(i)=v;
            if v<gb, gb=v; bVec=X(i,:); end
            T(fe)=gb;
        end
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','DEElimGWO-CEC','Rounds',rounds, ...
    'FinalPopulation',N,'MaxIter',maxIter,'RMode',rMode,'Source','paper-reconstruction');
end

