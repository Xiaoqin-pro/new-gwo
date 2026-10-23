function [Best,T,info]=CMAES_CEC(f,state,~,N,seed)
%CMAES_CEC  Bounded CMA-ES reference implementation for CEC2017.
%   The initial pool is reused as generation zero.  All candidates are
%   evaluated; no candidate is inserted into ranking before evaluation.
clockStart=tic;
D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound;
budget=state.maxEvaluations; lambda=max(4,round(N)); if isfield(state,'cmaLambda') && ~isempty(state.cmaLambda), lambda=max(4,round(state.cmaLambda)); end; mu=floor(lambda/2);
assert(budget>=size(state.initialPopulation,1));
rng(seed,'twister');
w=log(mu+0.5)-log(1:mu)'; w=w/sum(w);
mueff=1/sum(w.^2);
cc=(4+mueff/D)/(D+4+2*mueff/D);
cs=(mueff+2)/(D+mueff+5);
c1=2/((D+1.3)^2+mueff);
cmu=min(1-c1,2*(mueff-2+1/mueff)/((D+2)^2+mueff));
damps=1+2*max(0,sqrt((mueff-1)/(D+1))-1)+cs;
chiN=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
C=eye(D); pc=zeros(1,D); ps=zeros(1,D);
sigma=20; mean0=mean(state.initialPopulation,1);
T=nan(budget,1); Best.Cost=inf;
pop=state.initialPopulation; n0=min(size(pop,1),budget);
fitness=zeros(n0,1);
for i=1:n0
    fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost;
end
[~,ord]=sort(fitness); xmean=sum(w(1:min(mu,n0)).*pop(ord(1:min(mu,n0)),:),1);
if n0<mu, xmean=pop(ord(1),:); end
info.Evaluations=n0; info.Rounds=0; info.InitialCost=Best.Cost;
while info.Evaluations<budget
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); B=B*diag(sqrt(lam));
    if isfield(state,'cmaMirror') && state.cmaMirror
        Z=randn(lambda/2,D); Z=[Z;-Z];
    else
        Z=randn(lambda,D);
    end
    X=repmat(xmean,lambda,1)+sigma*(Z*B');
    X=reflectBounds(X,lb,ub);
    count=min(lambda,budget-info.Evaluations); X=X(1:count,:);
    vals=zeros(count,1);
    for i=1:count
        vals(i)=f(X(i,:)); T(info.Evaluations+i)=Best.Cost;
    end
    for i=1:count
        Best=UpdateBest(Best,X(i,:),vals(i)); T(info.Evaluations+i)=Best.Cost;
    end
    info.Evaluations=info.Evaluations+count; info.Rounds=info.Rounds+1;
    if count<mu || info.Evaluations>=budget
        break;
    end
    [~,ord]=sort(vals); sel=ord(1:mu);
    xold=xmean; xmean=sum(w.*X(sel,:),1);
    Y=(X(sel,:)-repmat(xold,mu,1))/sigma;
    ymean=sum(w.*Y,1);
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); invsqrt=B*diag(1./sqrt(lam))*B';
    ps=(1-cs)*ps+sqrt(cs*(2-cs)*mueff)*(invsqrt*(xmean-xold)')'/sigma;
    hsig=norm(ps)/sqrt(1-(1-cs)^(2*info.Rounds))/chiN < (1.4+2/(D+1));
    pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*mueff)*(xmean-xold)/sigma;
    C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(w)*Y);
    C=(C+C')/2;
    sigma=sigma*exp((cs/damps)*(norm(ps)/chiN-1));
    sigma=min(max(sigma,1e-10),1e4);
end
info.Algorithm='CMAES'; info.Seed=seed; info.Sigma=sigma; info.PopulationSize=lambda;
info.FinalMean=xmean; info.FinalCovariance=C; info.Seconds=toc(clockStart);
info.FinalCMAState=struct('Mean',xmean,'C',C,'Sigma',sigma,'PC',pc,'PS',ps, ...
    'Generation',info.Rounds,'Best',Best,'Evaluations',info.Evaluations);
end

function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
    low=X<lo; high=X>hi;
    if ~any(low(:)|high(:)), break; end
    X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end

function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost, Best.Vector=vector; Best.Cost=cost; end
end
