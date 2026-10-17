function [Best,T,info]=HAGWO_CEC(f,state,~,N,seed)
%HAGWO_CEC  HAGWO 移植（Mathematics 2026, 14(16):3011；作者源码
%   SylvanHuang/HAGWO @HAGWO_optimizer.m，逐机制对应：动态分层/分级对抗更新/
%   GWO 精英引导/Levy+p 权重）。
%  与作者代码的差异（仅接口与计费；逐条记录于 docs/15）：
%    * 初始种群由实验框架给定（与全部算法同一初始池）；不再调用其 initialization
%    * Avg_curve 的每代 N 次重复 fobj 调用改为使用已评价的 fitness（结果统计缓存，
%      不改变任何搜索行为，也不再重复计费）
%    * 每代恰好 N 次真实评价；Max_iter = floor((budget-N)/N)，FE 精确等于预算
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
fit=zeros(1,N); fe=0; gb=inf; bVec=X(1,:);
for i=1:N
    v=f(X(i,:)); fe=fe+1;
    if v<gb, gb=v; bVec=X(i,:); end
    T(fe)=gb; fit(i)=v;
end
MaxIter=floor((budget-N)/N);
beta=1.5;
sigma=(gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
for Iter=1:MaxIter
    [~,sort_idx]=sort(fit,'ascend');
    if Iter<=0.5*MaxIter
        n_superior=round(0.1*N); n_medium=round(0.3*N);
    else
        n_superior=round(0.3*N); n_medium=round(0.3*N);
    end
    n_superior=max(3,min(n_superior,N-2));
    n_medium=max(1,min(n_medium,N-n_superior));
    superior_idx=sort_idx(1:n_superior);
    medium_idx=sort_idx(n_superior+1:n_superior+n_medium);
    inferior_idx=sort_idx(n_superior+n_medium+1:end);
    Alpha_pos=X(sort_idx(1),:); Beta_pos=X(sort_idx(2),:); Delta_pos=X(sort_idx(3),:);
    p=1-Iter/MaxIter;
    levy=(randn(1,D)*sigma)./(abs(randn(1,D)).^(1/beta));
    lf=0.1*(1-Iter/MaxIter)*levy;
    a=2-Iter*(2/MaxIter);
    % ---- (1) 优狼组 ----
    for k=1:numel(superior_idx)
        i=superior_idx(k);
        [X1,X2,X3]=gwoCand(X(i,:),Alpha_pos,Beta_pos,Delta_pos,a);
        rj=superior_idx(randi(numel(superior_idx)));
        while rj==i, rj=superior_idx(randi(numel(superior_idx))); end
        Xn=p*((X1+X2+X3)/3)+(1-p)*X(rj,:);
        Xn=min(max(Xn,lb),ub);
        v=f(Xn); fe=fe+1; if v<gb, gb=v; bVec=Xn; end; T(fe)=gb;
        if v<fit(i), X(i,:)=Xn; fit(i)=v; end
    end
    % ---- (2) 中狼组 ----
    for k=1:numel(medium_idx)
        i=medium_idx(k);
        [X1,X2,X3]=gwoCand(X(i,:),Alpha_pos,Beta_pos,Delta_pos,a);
        avg=(X1+X2+X3)/3;
        r1i=superior_idx(randi(numel(superior_idx)));
        r2i=superior_idx(randi(numel(superior_idx)));
        temp=p*avg+(1-p)*X(r1i,:);
        Xn=temp+lf.*(X(i,:)-(p*avg+(1-p)*X(r2i,:)));
        Xn=min(max(Xn,lb),ub);
        v=f(Xn); fe=fe+1; if v<gb, gb=v; bVec=Xn; end; T(fe)=gb;
        if v<fit(i), X(i,:)=Xn; fit(i)=v; end
    end
    % ---- (3) 劣狼组 ----
    for k=1:numel(inferior_idx)
        i=inferior_idx(k);
        [X1,X2,X3]=gwoCand(X(i,:),Alpha_pos,Beta_pos,Delta_pos,a);
        avg=(X1+X2+X3)/3;
        m1=medium_idx(randi(numel(medium_idx)));
        m2=medium_idx(randi(numel(medium_idx)));
        temp=p*avg+(1-p)*(X(m1,:)+X(m2,:))/2;
        Xn=temp+lf.*(temp-X(i,:));
        Xn=min(max(Xn,lb),ub);
        v=f(Xn); fe=fe+1; if v<gb, gb=v; bVec=Xn; end; T(fe)=gb;
        if v<fit(i), X(i,:)=Xn; fit(i)=v; end
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','HAGWO-CEC','Rounds',MaxIter);
end

function [X1,X2,X3]=gwoCand(Xi,Alpha,Beta,Delta,a)
D=numel(Xi);
r1=rand(1,D); r2=rand(1,D); A1=2*a*r1-a; C1=2*r2;
X1=Alpha-A1.*abs(C1.*Alpha-Xi);
r1=rand(1,D); r2=rand(1,D); A2=2*a*r1-a; C2=2*r2;
X2=Beta-A2.*abs(C2.*Beta-Xi);
r1=rand(1,D); r2=rand(1,D); A3=2*a*r1-a; C3=2*r2;
X3=Delta-A3.*abs(C3.*Delta-Xi);
end
