function [Best,T,info]=MENGWO_CEC(f,state,~,N,seed)
%MENGWO_CEC  MENGWO 复现（Meng et al., Scientific Reports 2025,
%   doi:10.1038/s41598-025-33301-2；无官方代码 -> 按论文公式逐条实现）
%
%   机制（论文 Eq.1-16，全部保留）：
%     (1) 标准 GWO 三领导聚合（Eq.5-11，逐维 A/C）
%     (2) DE 启发的变异算子（Eq.12-13）：以标量 A 分支
%           |A|>=1 : Xg + r3*(X_rand1 - X_rand2)           （探索）
%           |A|< 1 : Xg + B*R.*(alpha - Xg), B=b*NFE/MaxNFE （利用）
%     (3) EPD 劣质个体重定位（Eq.14-15），k=0.25，q: q_ini=0.1 -> q_end=0.9
%     (4) NPSR 非线性种群缩减（Eq.16），n1=0.8，n2=3
%   原文参数：b=1.5, k=0.25, q_ini=0.1, q_end=0.9, n1=0.8, n2=3。
%
%   与论文的差异（接口 / 计费 / 时间轴，逐条）：
%     * 初始种群由实验框架给定（与全部算法同一初始池）
%     * 调度变量 a 与 B、q、NPSR 一律用真实 FE 进度 prog=fe/budget（原文用迭代号），
%       与全部算法的等 FE 协议一致
%     * 论文每轮在轮首重新评价全群；本实现把"全群评价"放在每轮末尾（对同一组位置、
%       同样次数），使 EPD 重定位后的位置在下一轮开始时已被真实评价，从而任何被排序的
%       个体都带真实适应度（AGENTS 第三节：未经真实评价的点不得参与排序）
%     * NPSR 淘汰在排序之后执行：保留适应度最好的 N_{G+1} 个（fitness 为已验证值）
%     * 预算边界处按剩余 FE 逐次评价，绝不超支
X=state.initialPopulation;
[N0init,D]=size(X);
assert(N0init==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
N0=N;                        % NPSR 的初始规模
bCoef=1.5; kFrac=0.25; qIni=0.1; qEnd=0.9; n1=0.8; n2=3;
fit=inf(N,1); fe=0; gb=inf; bVec=X(1,:);
% ---- 初始评价 ----
for i=1:N
    v=f(X(i,:)); fe=fe+1; fit(i)=v;
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb;
end
rounds=0;
while fe<budget
    rounds=rounds+1;
    prog=fe/budget;
    % ---- 领导（仅用已验证适应度） ----
    [~,ord]=sort(fit,'ascend');
    Alpha=X(ord(1),:); Beta=X(ord(2),:); Delta=X(ord(3),:);
    a=2*(1-prog);
    B=bCoef*prog;
    % ---- Eq.12 位置更新（逐维 A/C 的三领导聚合 + 变异算子） ----
    for i=1:N
        r1=rand(1,D); r2=rand(1,D); A1=2*a*r1-a; C1=2*r2;
        X1=Alpha-A1.*abs(C1.*Alpha-X(i,:));
        r1=rand(1,D); r2=rand(1,D); A2=2*a*r1-a; C2=2*r2;
        X2=Beta -A2.*abs(C2.*Beta -X(i,:));
        r1=rand(1,D); r2=rand(1,D); A3=2*a*r1-a; C3=2*r2;
        X3=Delta-A3.*abs(C3.*Delta-X(i,:));
        Xg=(X1+X2+X3)/3;
        As=2*a*rand()-a;               % Eq.12 的标量分支判据
        if abs(As)>=1
            r3=rand();
            p=randperm(N,2);
            while any(p==i), p=randperm(N,2); end
            Xn=Xg+r3*(X(p(1),:)-X(p(2),:));
        else
            Xn=Xg+B*rand(1,D).*(Alpha-Xg);
        end
        X(i,:)=min(max(Xn,lb),ub);
    end
    % ---- Eq.16 NPSR：保留最优的 N_{G+1} 个 ----
    Nnext=max(3,round(N0*(1-n1*prog^n2)));
    if Nnext<N
        [~,ord]=sort(fit,'ascend');
        keep=sort(ord(1:Nnext));
        X=X(keep,:); fit=fit(keep); N=Nnext;
    end
    % ---- Eq.14 EPD：重定位最差的 k 比例 ----
    kk=max(1,round(kFrac*N));
    [~,ord]=sort(fit,'ascend');
    worst=ord(end-kk+1:end);
    q=qIni+(qEnd-qIni)*prog;
    for t=1:numel(worst)
        i=worst(t);
        if rand()<q
            Xn=X(i,:)+(Alpha-rand(1,D).*X(i,:));
        else
            Xn=lb+(ub-lb).*rand(1,D);
        end
        X(i,:)=min(max(Xn,lb),ub);
    end
    % ---- 全群真实评价（位置已更新/重定位） ----
    for i=1:N
        if fe>=budget, break; end
        v=f(X(i,:)); fe=fe+1; fit(i)=v;
        if v<gb, gb=v; bVec=X(i,:); end
        T(fe)=gb;
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','MENGWO-CEC','Rounds',rounds, ...
    'FinalPopulation',N,'Source','paper-reconstruction');
end
