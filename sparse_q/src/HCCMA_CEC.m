function [Best,T,info]=HCCMA_CEC(f,state,~,N,seed)
clockStart=tic;
%HCCMA_CEC  Heterogeneous full/diagonal covariance CMA with a shared mean.
D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
shareF=0.70; if isfield(state,'hcShareF') && ~isempty(state.hcShareF), shareF=min(0.9,max(0.1,state.hcShareF)); end
rng(seed,'twister'); lambda=50; mu=floor(lambda/2); w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); me=1/sum(w.^2);
cc=(4+me/D)/(D+4+2*me/D); cs=(me+2)/(D+me+5); c1=2/((D+1.3)^2+me); cmu=min(1-c1,2*(me-2+1/me)/((D+2)^2+me));
damps=1+2*max(0,sqrt((me-1)/(D+1))-1)+cs; chi=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
n0=min(size(state.initialPopulation,1),budget); pop=state.initialPopulation(1:n0,:); fit=zeros(n0,1); T=nan(budget,1); Best.Cost=inf;
for i=1:n0, fit(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fit(i)); T(i)=Best.Cost; end
used=n0; [~,o]=sort(fit); m=mean(pop(o(1:max(2,round(0.5*n0))),:),1);
Cf=eye(D); Cd=ones(1,D); pcF=zeros(1,D); psF=zeros(1,D); pcD=zeros(1,D); psD=zeros(1,D); sig=20; rounds=0; evalF=0; evalD=0;
while used<budget
 rounds=rounds+1; n=min(lambda,budget-used); nF=round(shareF*n); nD=n-nF; if nD<2, nF=n-2; nD=2; end
 % full covariance samples
 [E,L]=eig((Cf+Cf')/2); L=max(diag(L),1e-14); E=E*diag(sqrt(L)); XF=repmat(m,nF,1)+sig*(randn(nF,D)*E'); XF=clip(XF,lb,ub);
 % diagonal covariance samples
 XD=repmat(m,nD,1)+sig*(randn(nD,D).*repmat(sqrt(Cd),nD,1)); XD=clip(XD,lb,ub);
 X=[XF;XD]; vals=zeros(n,1);
 for j=1:n, vals(j)=f(X(j,:)); used=used+1; Best=UpdateBest(Best,X(j,:),vals(j)); T(used)=Best.Cost; end
 evalF=evalF+nF; evalD=evalD+nD; [~,o]=sort(vals); mu2=min(mu,max(2,floor(n/2))); w2=log(mu2+0.5)-log(1:mu2)'; w2=w2/sum(w2); old=m; m=sum(w2.*X(o(1:mu2),:),1);
 % update full expert
 if nF>=4
  [~,of]=sort(vals(1:nF)); muf=max(2,floor(nF/2)); wf=log(muf+0.5)-log(1:muf)'; wf=wf/sum(wf); Xs=XF(of(1:muf),:); Y=(Xs-repmat(old,muf,1))/sig;
  [E,L]=eig((Cf+Cf')/2); L=max(diag(L),1e-14); inv=E*diag(1./sqrt(L))*E';
  psF=(1-cs)*psF+sqrt(cs*(2-cs)*me)*(inv*(m-old)')'/sig; hf=norm(psF)/sqrt(1-(1-cs)^2)/chi<(1.4+2/(D+1));
  pcF=(1-cc)*pcF+double(hf)*sqrt(cc*(2-cc)*me)*(m-old)/sig;
  Cf=(1-c1-cmu)*Cf+c1*(pcF'*pcF+double(~hf)*cc*(2-cc)*Cf)+cmu*(Y'*diag(wf)*Y); Cf=(Cf+Cf')/2;
 end
 % update diagonal expert
 if nD>=4
  [~,od]=sort(vals(nF+1:end)); mud=max(2,floor(nD/2)); wd=log(mud+0.5)-log(1:mud)'; wd=wd/sum(wd); Xs=XD(od(1:mud),:); Y=(Xs-repmat(old,mud,1))/sig;
  vd=sum(wd.*(Y.^2),1); Cd=0.9*Cd+0.1*max(vd,1e-8); Cd=Cd/(mean(Cd)+1e-12); Cd=min(max(Cd,1e-6),1e3);
  psD=0.9*psD+0.1*(m-old)/sig; pcD=0.9*pcD+0.1*(m-old)/sig;
 end
 sig=sig*exp((cs/damps)*(norm(psF)/chi-1)); sig=min(max(sig,1e-10),1e4);
end
info.Algorithm='HCCMA'; info.Evaluations=used; info.Rounds=rounds; info.ShareF=shareF; info.EvalF=evalF; info.EvalD=evalD; info.Sigma=sig;
info.FinalCMAState=struct('Mean',m,'C',Cf,'Sigma',sig,'PC',pcF,'PS',psF,'Generation',rounds,'Best',Best,'Evaluations',used); info.FinalDiag=Cd; info.Seconds=toc(clockStart);
end
function X=clip(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
