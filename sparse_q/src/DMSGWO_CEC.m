function [Best,T,info]=DMSGWO_CEC(f,state,~,N,seed)
%DMSGWO_CEC  MATLAB implementation of DMSGWO (Dynamic Multi-Strategy GWO)
%   Wang, Song, Zhao, Jiang, Scientific Reports 16:23295 (2026),
%   doi:10.1038/s41598-026-54428-w (open access).
%
%   实现依据与标注：
%   * 官方 GitHub (wangyoki/DMSGWO) 的 dmsgwo 文件中，**开发组更新循环为空**
%     （`for i=n1+1:N ... %% ... end`）。本实现按论文公式补全该分支：
%       phi = (f_i / f_avg)^3 ； w = 0.5 + 0.5*cos(pi*t/T)
%       X_new = (1-w)*X + w*X.*phi      （逐维；贪心接受）
%   * 非线性收敛因子：a = 2/log10(2)*log10(2-(t/T)^3)
%   * 探索组（前 n1 只狼）按源码结构逐维产生候选：p>0.5 时
%     X + rand*(X-Xalpha).*Levy(D)；否则 X + rand*(X_r1-X_r2)（两随机狼，
%     逐维取值），贪心接受；
%   * 分组规模动态调整与源码一致（改进→n1-1；连续≥3 代无改善→n1+1）。
%   * 所有 `f` 调用都是真实评价并计费；t/T 以真实 FE 进度计（fe/budget），
%     与等 FE 协议一致。
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D));
Beta=Alpha; Delta=Alpha;

n1=round(N*0.5); n2=N-n1;
noImp=0; prevBest=inf;
gb=inf; fe=0;
fit=inf(N,1);
Positions=X;
for i=1:N
    v=f(Positions(i,:)); fe=fe+1; gb=min(gb,v); T(fe)=gb;
    fit(i)=v;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,Positions(i,:),v);
end
betaL=1.5;
it=0;
while fe<budget
    it=it+1;
    prog=fe/budget;
    % ---- 探索组（前 n1 只，逐维候选） ----
    for i=1:n1
        for j=1:D
            if fe>=budget, break; end
            p=rand();
            if p>0.5
                lev=levyVec(D,betaL);
                newpop=Positions(i,:)+rand()*(Positions(i,j)-Alpha.Vector(j)).*lev;
            else
                ri=randperm(N,2);
                newpop=Positions(i,:)+rand()*(Positions(ri(1),j)-Positions(ri(2),j));
            end
            newpop=min(max(newpop,lb),ub);
            v=f(newpop); fe=fe+1; gb=min(gb,v); T(fe)=gb;
            if v<fit(i)
                fit(i)=v; Positions(i,:)=newpop;
                [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,newpop,v);
            end
        end
    end
    % ---- 开发组（后 n2 只，自适应扰动，论文公式补全） ----
    favg=mean(fit);
    w=0.5+0.5*cos(pi*prog);
    for i=n1+1:N
        if fe>=budget, break; end
        phi=(fit(i)/favg)^3;
        newpop=(1-w)*Positions(i,:)+w*Positions(i,:).*phi;
        newpop=min(max(newpop,lb),ub);
        v=f(newpop); fe=fe+1; gb=min(gb,v); T(fe)=gb;
        if v<fit(i)
            fit(i)=v; Positions(i,:)=newpop;
            [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,newpop,v);
        end
    end
    % ---- 分组规模动态调整（与作者源码一致） ----
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

Best=struct('Cost',Alpha.Cost,'Vector',Alpha.Vector);
info=struct('Evaluations',fe,'Algorithm','DMSGWO-CEC','Rounds',it);
end

function L=levyVec(D,beta)
sigma=(gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
u=randn(1,D)*sigma;
v=randn(1,D);
L=u./abs(v).^(1/beta);
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
