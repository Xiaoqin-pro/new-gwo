function [Best,T,info]=PSO_CEC(f,state,~,N,seed)
%PSO_CEC  经典粒子群优化（Kennedy & Eberhart 1995；Shi & Eberhart 1998 惯性权重）
%   速度更新：v = w*v + c1*r1.*(pbest-x) + c2*r2.*(gbest-x)；x = x + v
%   参数（最常用的经典基准配置，全文照录）：
%     w: 线性递减 0.9 -> 0.4；c1 = c2 = 2.0；vmax = 0.2*(ub-lb)（逐维限幅）；
%     位置越界按边界截断；每维独立 r1,r2 ~ U(0,1)。
%   与实验框架的适配（仅接口/计费，同其它算法）：
%     * 初始种群由框架给定（同池协议）
%     * 初始化 N 次真实评价；每代先在移动后评价 N 个新位置；
%       MaxIter = floor((budget-N)/N) => 真实 FE 精确等于预算
%     * pbest/gbest 仅由真实评价更新；未评价位置不进入任何排序
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
V=zeros(N,D); vmax=0.2*(ub-lb);
c1=2.0; c2=2.0;
fe=0; gb=inf; bVec=X(1,:); pbest=X; pbestFit=inf(N,1);
for i=1:N
    v=f(X(i,:)); fe=fe+1;
    pbestFit(i)=v; pbest(i,:)=X(i,:);
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb;
end
MaxIter=floor((budget-N)/N);
for Iter=1:MaxIter
    w=0.9-0.5*(Iter/MaxIter);
    for i=1:N
        r1=rand(1,D); r2=rand(1,D);
        V(i,:)=w*V(i,:)+c1*r1.*(pbest(i,:)-X(i,:))+c2*r2.*(bVec-X(i,:));
        V(i,:)=min(max(V(i,:),-vmax),vmax);
        X(i,:)=min(max(X(i,:)+V(i,:),lb),ub);
        v=f(X(i,:)); fe=fe+1;
        if v<pbestFit(i), pbestFit(i)=v; pbest(i,:)=X(i,:); end
        if v<gb, gb=v; bVec=X(i,:); end
        T(fe)=gb;
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','PSO-CEC','Rounds',MaxIter);
end
