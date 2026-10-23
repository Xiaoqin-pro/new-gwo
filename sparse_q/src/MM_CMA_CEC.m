function [Best,T,info]=MM_CMA_CEC(f,state,~,N,seed)
%MM_CMA_CEC  Multi-mean CMA with one shared covariance learned by the main mean.
K=3; shares=[0.70 0.15 0.15];
if isfield(state,'mmShares') && ~isempty(state.mmShares), shares=state.mmShares(:)'; K=numel(shares); end
if K~=numel(shares), shares=ones(1,K)/K; end
shares=shares/sum(shares); D=size(state.initialPopulation,2); budget=state.maxEvaluations; lb=state.lowerBound; ub=state.upperBound;
rng(seed,'twister'); n0=min(size(state.initialPopulation,1),budget); pop=state.initialPopulation(1:n0,:);
T=nan(budget,1); Best.Cost=inf; fitness=zeros(n0,1);
for i=1:n0, fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost; end
used=n0; [~,ord]=sort(fitness); mu0=max(2,round(0.5*n0));
means=zeros(K,D); means(1,:)=mean(pop(ord(1:mu0),:),1);
for k=2:K
 d=zeros(n0,1); for q=1:n0, d(q)=min(sqrt(sum((means(1:k-1,:)-repmat(pop(q,:),k-1,1)).^2,2))); end
 [~,di]=max(d); means(k,:)=pop(di,:);
end
C=eye(D); pc=zeros(1,D); ps=zeros(1,D); sigma=20; rounds=0; nicheEval=zeros(1,K);
while used<budget
 rounds=rounds+1; nt=min(50,budget-used); counts=allocCounts(shares,nt); Xc=cell(K,1); Vc=cell(K,1);
 for k=1:K
  n=counts(k); if n<=0, Xc{k}=zeros(0,D); Vc{k}=zeros(0,1); continue; end
  [E,L]=eig((C+C')/2); L=max(diag(L),1e-14); E=E*diag(sqrt(L));
  X=repmat(means(k,:),n,1)+sigma*(randn(n,D)*E'); X=clip(X,lb,ub); vals=zeros(n,1);
  for j=1:n, vals(j)=f(X(j,:)); used=used+1; Best=UpdateBest(Best,X(j,:),vals(j)); T(used)=Best.Cost; end
  Xc{k}=X; Vc{k}=vals; nicheEval(k)=nicheEval(k)+n;
 end
 [means(1,:),C,pc,ps,sigma]=updateMain(means(1,:),C,pc,ps,sigma,Xc{1},Vc{1});
 for k=2:K
  n=size(Xc{k},1); if n>=2
   [~,o]=sort(Vc{k}); mu=max(2,floor(n/2)); w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); means(k,:)=sum(w.*Xc{k}(o(1:mu),:),1);
  end
 end
end
info.Algorithm='MM-CMA'; info.Evaluations=used; info.Rounds=rounds; info.NicheK=K; info.NicheMeans=means;
info.NicheEval=nicheEval; info.Shares=shares; info.Sigma=sigma; info.FinalCMAState=struct('Mean',means(1,:),'C',C,'Sigma',sigma,'PC',pc,'PS',ps,'Generation',rounds,'Best',Best,'Evaluations',used);
end
function c=allocCounts(w,n)
w=w/sum(w); raw=w*n; c=floor(raw); [~,o]=sort(raw-c,'descend'); for j=1:n-sum(c), c(o(mod(j-1,numel(c))+1))=c(o(mod(j-1,numel(c))+1))+1; end
end
function [m,C,pc,ps,sig]=updateMain(m,C,pc,ps,sig,X,vals)
n=size(X,1); if n<4, return; end; mu=max(2,floor(n/2)); w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); me=1/sum(w.^2); D=numel(m);
cc=(4+me/D)/(D+4+2*me/D); cs=(me+2)/(D+me+5); c1=2/((D+1.3)^2+me); cmu=min(1-c1,2*(me-2+1/me)/((D+2)^2+me));
damps=1+2*max(0,sqrt((me-1)/(D+1))-1)+cs; chi=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
[~,o]=sort(vals); old=m; m=sum(w.*X(o(1:mu),:),1); Y=(X(o(1:mu),:)-repmat(old,mu,1))/sig;
[E,L]=eig((C+C')/2); L=max(diag(L),1e-14); inv=E*diag(1./sqrt(L))*E';
ps=(1-cs)*ps+sqrt(cs*(2-cs)*me)*(inv*(m-old)')'/sig; hs=norm(ps)/sqrt(1-(1-cs)^2)/chi<(1.4+2/(D+1));
pc=(1-cc)*pc+double(hs)*sqrt(cc*(2-cc)*me)*(m-old)/sig;
C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hs)*cc*(2-cc)*C)+cmu*(Y'*diag(w)*Y); C=(C+C')/2;
sig=sig*exp((cs/damps)*(norm(ps)/chi-1)); sig=min(max(sig,1e-10),1e4);
end
function X=clip(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
