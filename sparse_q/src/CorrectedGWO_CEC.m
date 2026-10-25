function [Best,T,info]=CorrectedGWO_CEC(f,state,~,N,seed)
%CORRECTED GWO -- **DROPPED 2026-10-25 (user decision)**
%   该基线已从对比集中移除：Corrected GWO 因原文公式不可得（论文站点 captcha、
%   FEX 需登录）只能按一句话机制描述重建，证据强度不足；DE-Elim GWO 因 Eq.18
%   在正文与公式中自相矛盾。文件保留为存档，不注册到 runner_sgwo、不进入任何
%   正式批次。替代基线见 IAGWO_CEC.m（2024, AI Review, 公式完整）。
%CorrectedGWO_CEC  Corrected GWO 复现（Tsai & Shi, Applied Soft Computing 2024,
%   doi:10.1016/j.asoc.2024.111776；FEX 162131 "Corrected grey wolf optimizer for
%   continuous optimization"）
%
%   来源状态（如实记录）：论文正文站点被 captcha 拦截、FEX 下载需登录，
%   仅取得 FEX 条目的机制描述（refs/CorrectedGWO_2024/fex_page.md）。因此本实现是
%   **按三条已公开的修正说明重建**，不是作者源码移植。三条修正（FEX 原文）：
%     (i)   eliminating coefficient factor C          -> 距离项不再乘 C
%     (ii)  eliminating the absolute sign for factor D -> 距离项保留符号
%     (iii) introducing a current-to-prey approach     -> 更新式以当前位置为起点
%   原文称由此得到两个修正变体，其中一个在 CEC2005 上与其他主流算法相当。
%
%   本实现的两个变体（state.cgwoVariant）：
%     'c1' 修正 (i)+(ii)： Xk = Xl - Ak.*(Xl - X)      （有符号距离，去 C）
%     'c2' 修正 (i)+(ii)+(iii)：Xk = X + Ak.*(Xl - X)  （current-to-prey）
%   默认 'c2'（三条修正全开）；'c1' 保留为对照，两者都在确认集中报告。
%   两者均以 Xnew = mean(X1,X2,X3) 聚合，a 线性 2->0，A=2*a*r-a 逐维。
%
%   与原文的差异（接口 / 计费 / 时间轴，逐条）：
%     * 初始种群由实验框架给定（与全部算法同一初始池）
%     * a 的时间轴用真实 FE 进度 fe/budget（原文用迭代号），与全部算法等 FE 一致
%     * 每代恰好 N 次真实评价，预算边界逐次检查，绝不超支
%     * 由于原文公式未公开，Ak 的抽样范围沿用 GWO 的 [−a,a]（未做任何按函数调节）
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
variant='c2';
if isfield(state,'cgwoVariant') && ~isempty(state.cgwoVariant), variant=char(state.cgwoVariant); end
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
fe=0; gb=inf; bVec=X(1,:);
for i=1:N
    v=f(X(i,:)); fe=fe+1;
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb;
    [Alpha,Beta,Delta]=cascade(Alpha,Beta,Delta,X(i,:),v);
end
rounds=0;
while fe<budget
    rounds=rounds+1;
    a=2*(1-fe/budget);
    L={Alpha.Vector,Beta.Vector,Delta.Vector};
    for i=1:N
        if fe>=budget, break; end
        acc=zeros(1,D);
        for kk=1:3
            Ak=2*a*rand(1,D)-a;
            if strcmp(variant,'c1')
                Xk=L{kk}-Ak.*(L{kk}-X(i,:));
            else
                Xk=X(i,:)+Ak.*(L{kk}-X(i,:));
            end
            acc=acc+Xk;
        end
        Xn=min(max(acc/3,lb),ub);
        X(i,:)=Xn;
        v=f(Xn); fe=fe+1;
        if v<gb, gb=v; bVec=Xn; end
        T(fe)=gb;
        [Alpha,Beta,Delta]=cascade(Alpha,Beta,Delta,Xn,v);
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','CorrectedGWO-CEC','Rounds',rounds, ...
    'Variant',variant,'Source','FEX-mechanism-reconstruction');
end

function [A,B,Dl]=cascade(A,B,Dl,x,v)
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end
