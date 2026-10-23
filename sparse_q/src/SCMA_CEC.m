function [Best,T,info]=SCMA_CEC(f,state,~,N,seed)
clockStart=tic;
%SCMA_CEC  Sparse-evaluation CMA-ES with dual-potential screening.
D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
lambda=100; K=50; if isfield(state,'scmaLambda') && ~isempty(state.scmaLambda), lambda=max(4,round(state.scmaLambda)); end
if isfield(state,'scmaK') && ~isempty(state.scmaK), K=max(4,round(state.scmaK)); end
if K>lambda, K=lambda; end
mu=floor(K/2); rng(seed,'twister'); w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); me=1/sum(w.^2);
cc=(4+me/D)/(D+4+2*me/D); cs=(me+2)/(D+me+5); c1=2/((D+1.3)^2+me); cmu=min(1-c1,2*(me-2+1/me)/((D+2)^2+me));
damps=1+2*max(0,sqrt((me-1)/(D+1))-1)+cs; chi=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
n0=min(size(state.initialPopulation,1),budget); pop=state.initialPopulation(1:n0,:); fit=zeros(n0,1); T=nan(budget,1); Best.Cost=inf;
for i=1:n0, fit(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fit(i)); T(i)=Best.Cost; end
used=n0; [~,o]=sort(fit); m=mean(pop(o(1:max(2,round(0.5*n0))),:),1); C=eye(D); pc=zeros(1,D); ps=zeros(1,D); sigma=20; rounds=0;
while used<budget
 rounds=rounds+1; [E,L]=eig((C+C')/2); L=max(diag(L),1e-14); E=E*diag(sqrt(L));
 X=repmat(m,lambda,1)+sigma*(randn(lambda,D)*E'); X=clip(X,lb,ub);
 near=round(0.5*K); d=sqrt(sum((X-repmat(m,lambda,1)).^2,2)); [~,ord]=sort(d); sel=ord(1:near);
 rem=setdiff((1:lambda)',sel); [~,fi]=max(d(rem)); pick=rem(fi); sel(end+1)=pick; rem(rem==pick)=[];
 while numel(sel)<K && ~isempty(rem)
  dd=zeros(numel(rem),1); for q=1:numel(rem), dd(q)=min(sqrt(sum((X(sel,:)-repmat(X(rem(q),:),numel(sel),1)).^2,2))); end
  [~,qi]=max(dd); pick=rem(qi); sel(end+1)=pick; rem(rem==pick)=[]; %#ok<AGROW>
 end
 sel=sel(1:K); count=min(numel(sel),budget-used); sel=sel(1:count); vals=zeros(count,1);
 for j=1:count, vals(j)=f(X(sel(j),:)); used=used+1; Best=UpdateBest(Best,X(sel(j),:),vals(j)); T(used)=Best.Cost; end
 [~,o]=sort(vals); mu2=min(mu,max(2,floor(count/2))); w2=log(mu2+0.5)-log(1:mu2)'; w2=w2/sum(w2);
 Xs=X(sel(o(1:mu2)),:); old=m; m=sum(w2.*Xs,1); Y=(Xs-repmat(old,mu2,1))/sigma;
 [E,L]=eig((C+C')/2); L=max(diag(L),1e-14); I=E*diag(1./sqrt(L))*E';
 ps=(1-cs)*ps+sqrt(cs*(2-cs)*me)*(I*(m-old)')'/sigma; hs=norm(ps)/sqrt(1-(1-cs)^2)/chi<(1.4+2/(D+1));
 pc=(1-cc)*pc+double(hs)*sqrt(cc*(2-cc)*me)*(m-old)/sigma;
 C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hs)*cc*(2-cc)*C)+cmu*(Y'*diag(w2)*Y); C=(C+C')/2;
 sigma=sigma*exp((cs/damps)*(norm(ps)/chi-1)); sigma=min(max(sigma,1e-10),1e4);
end
info.Algorithm='SCMA'; info.Evaluations=used; info.Rounds=rounds; info.Lambda=lambda; info.K=K; info.Sigma=sigma; info.FinalCMAState=struct('Mean',m,'C',C,'Sigma',sigma,'PC',pc,'PS',ps,'Generation',rounds,'Best',Best,'Evaluations',used); info.Seconds=toc(clockStart);
end
function X=clip(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
