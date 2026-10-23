function [Best,T,info]=CMAES_RESUME(f,state,~,N,seed)
%CMAES_RESUME  Continue a CMA-ES distribution from a verified checkpoint.
clockStart=tic; budget=state.maxEvaluations; D=size(state.cmaState.Mean,2);
lb=state.lowerBound; ub=state.upperBound; lambda=max(4,round(N)); mu=floor(lambda/2);
rng(seed,'twister');
w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); mueff=1/sum(w.^2);
cc=(4+mueff/D)/(D+4+2*mueff/D); cs=(mueff+2)/(D+mueff+5);
c1=2/((D+1.3)^2+mueff); cmu=min(1-c1,2*(mueff-2+1/mueff)/((D+2)^2+mueff));
damps=1+2*max(0,sqrt((mueff-1)/(D+1))-1)+cs;
chiN=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
xmean=state.cmaState.Mean; C=state.cmaState.C; sigma=state.cmaState.Sigma;
pc=state.cmaState.PC; ps=state.cmaState.PS; Best=state.cmaState.Best;
gen0=state.cmaState.Generation; evals=0; T=nan(budget,1); firstBlock=true;
while evals<budget
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); B=B*diag(sqrt(lam));
    Z=randn(lambda,D); X=repmat(xmean,lambda,1)+sigma*(Z*B');
    if firstBlock && isfield(state,'cmaInject') && ~isempty(state.cmaInject)
        inj=state.cmaInject; ni=min(size(inj,1),size(X,1)); X(1:ni,:)=inj(1:ni,:);
    end
    X=reflectBounds(X,lb,ub); firstBlock=false;
    count=min(lambda,budget-evals); X=X(1:count,:); vals=zeros(count,1);
    for i=1:count
        vals(i)=f(X(i,:)); evals=evals+1; Best=UpdateBest(Best,X(i,:),vals(i)); T(evals)=Best.Cost;
    end
    if count<mu || evals>=budget, break; end
    [~,ord]=sort(vals); sel=ord(1:mu); xold=xmean;
    xmean=sum(w.*X(sel,:),1); Y=(X(sel,:)-repmat(xold,mu,1))/sigma;
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); invsqrt=B*diag(1./sqrt(lam))*B';
    ps=(1-cs)*ps+sqrt(cs*(2-cs)*mueff)*(invsqrt*(xmean-xold)')'/sigma;
    g=gen0+ceil(evals/lambda);
    hsig=norm(ps)/sqrt(1-(1-cs)^(2*g))/chiN < (1.4+2/(D+1));
    pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*mueff)*(xmean-xold)/sigma;
    C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(w)*Y);
    C=(C+C')/2; sigma=sigma*exp((cs/damps)*(norm(ps)/chiN-1)); sigma=min(max(sigma,1e-10),1e4);
end
info.Algorithm='CMAES-RESUME'; info.Evaluations=evals; info.Rounds=ceil(evals/lambda);
info.Sigma=sigma; info.PopulationSize=lambda; info.FinalMean=xmean; info.FinalCovariance=C;
info.FinalCMAState=struct('Mean',xmean,'C',C,'Sigma',sigma,'PC',pc,'PS',ps, ...
    'Generation',gen0+info.Rounds,'Best',Best,'Evaluations',evals);
info.Seconds=toc(clockStart);
end

function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
    low=X<lo; high=X>hi; if ~any(low(:)|high(:)), break; end
    X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end

function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost, Best.Vector=vector; Best.Cost=cost; end
end
