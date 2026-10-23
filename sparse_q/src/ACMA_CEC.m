function [Best,T,info]=ACMA_CEC(f,state,~,N,seed)
clockStart=tic;
%ACMA_CEC  CMA-ES with a verified elite archive contributing to covariance learning.
D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
lambda=max(4,round(N)); mu=floor(lambda/2); rng(seed,'twister');
w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); me=1/sum(w.^2);
cc=(4+me/D)/(D+4+2*me/D); cs=(me+2)/(D+me+5); c1=2/((D+1.3)^2+me); cmu=min(1-c1,2*(me-2+1/me)/((D+2)^2+me));
damps=1+2*max(0,sqrt((me-1)/(D+1))-1)+cs; chi=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
rho=0.05; if isfield(state,'acmaRho') && ~isempty(state.acmaRho), rho=max(0,min(0.3,state.acmaRho)); end
n0=min(size(state.initialPopulation,1),budget); pop=state.initialPopulation(1:n0,:); fit=zeros(n0,1); T=nan(budget,1); Best.Cost=inf;
for i=1:n0, fit(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fit(i)); T(i)=Best.Cost; end
used=n0; [~,o]=sort(fit); m=mean(pop(o(1:max(2,round(0.5*n0))),:),1); C=eye(D); pc=zeros(1,D); ps=zeros(1,D); sigma=20; rounds=0;
archX=zeros(0,D); archF=zeros(0,1); span=norm(ub-lb); cap=30;
while used<budget
 rounds=rounds+1; [E,L]=eig((C+C')/2); L=max(diag(L),1e-14); E=E*diag(sqrt(L));
 Z=randn(lambda,D); X=repmat(m,lambda,1)+sigma*(Z*E'); X=clip(X,lb,ub); count=min(lambda,budget-used); X=X(1:count,:); vals=zeros(count,1);
 for i=1:count, vals(i)=f(X(i,:)); used=used+1; Best=UpdateBest(Best,X(i,:),vals(i)); T(used)=Best.Cost; end
 [~,o]=sort(vals); mu2=min(mu,max(2,floor(count/2))); w2=log(mu2+0.5)-log(1:mu2)'; w2=w2/sum(w2);
 Xs=X(o(1:mu2),:); old=m; m=sum(w2.*Xs,1); Y=(Xs-repmat(old,mu2,1))/sigma;
 [E,L]=eig((C+C')/2); L=max(diag(L),1e-14); I=E*diag(1./sqrt(L))*E';
 ps=(1-cs)*ps+sqrt(cs*(2-cs)*me)*(I*(m-old)')'/sigma; hs=norm(ps)/sqrt(1-(1-cs)^2)/chi<(1.4+2/(D+1));
 pc=(1-cc)*pc+double(hs)*sqrt(cc*(2-cc)*me)*(m-old)/sigma;
 C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hs)*cc*(2-cc)*C)+cmu*(Y'*diag(w2)*Y); C=(C+C')/2;
 med=median(vals);
 for i=1:count
  if vals(i)<=med || vals(i)<Best.Cost
   [archX,archF]=adm(archX,archF,X(i,:),vals(i),cap,0.02,span);
  end
 end
 if ~isempty(archX)
  kk=min(size(archX,1),15); [~,ao]=sort(archF); A=archX(ao(1:kk),:); YA=(A-repmat(m,kk,1))/sigma;
  wa=ones(kk,1)/kk; Ca=YA'*diag(wa)*YA; sc=mean(diag(Ca))+1e-12; Ca=Ca/sc*mean(diag(C));
  C=(1-rho)*C+rho*Ca; C=(C+C')/2;
 end
 sigma=sigma*exp((cs/damps)*(norm(ps)/chi-1)); sigma=min(max(sigma,1e-10),1e4);
end
info.Algorithm='ACMA'; info.Evaluations=used; info.Rounds=rounds; info.ArchiveSize=size(archX,1); info.Sigma=sigma; info.Rho=rho;
info.FinalCMAState=struct('Mean',m,'C',C,'Sigma',sigma,'PC',pc,'PS',ps,'Generation',rounds,'Best',Best,'Evaluations',used); info.Seconds=toc(clockStart);
end
function [X,F]=adm(X,F,x,v,cap,sep,span)
if isempty(X), X=x; F=v; return; end
d=sqrt(sum((X-repmat(x,size(X,1),1)).^2,2))/span; [dmin,ni]=min(d);
if dmin>=sep
 if size(X,1)<cap, X(end+1,:)=x; F(end+1,1)=v; else [~,wi]=max(F); if v<F(wi), X(wi,:)=x; F(wi)=v; end; end
elseif v<F(ni), X(ni,:)=x; F(ni)=v; end
end
function X=clip(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
