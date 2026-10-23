function [Best,T,info]=MNC_CMA_CEC(f,state,~,N,seed)
%MNC_CMA_CEC  Multi-niche CMA-ES with per-niche covariance states.
%   A main niche and K-1 scout niches sample independently.  Each niche has
%   its own mean/C/sigma/pc/ps and is updated only from its own evaluated
%   samples.  Fixed shares are the controlled ablation; adaptive shares use
%   recent real best improvement to reallocate evaluations.
clockStart=tic; D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound;
budget=state.maxEvaluations; K=3; baseW=[0.50 0.25 0.25];
if isfield(state,'mncK') && ~isempty(state.mncK), K=max(2,round(state.mncK)); end
if K~=3, baseW=ones(1,K)/K; end
if isfield(state,'mncShares') && ~isempty(state.mncShares)
    baseW=state.mncShares(:)'; assert(numel(baseW)==K && all(baseW>0)); baseW=baseW/sum(baseW);
end
mode='fixed'; if isfield(state,'mncMode') && ~isempty(state.mncMode), mode=lower(char(state.mncMode)); end
window=1000; if isfield(state,'mncWindow') && ~isempty(state.mncWindow), window=max(100,round(state.mncWindow)); end
rng(seed,'twister');
n0=min(size(state.initialPopulation,1),budget); pop=state.initialPopulation(1:n0,:);
T=nan(budget,1); Best.Cost=inf; fitness=zeros(n0,1);
for i=1:n0
    fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost;
end
used=n0; [~,ord]=sort(fitness);
means=zeros(K,D); C=cell(K,1); pc=zeros(K,D); ps=zeros(K,D); sigma=20*ones(K,1);
mu0=max(2,min(n0,round(0.5*n0))); means(1,:)=mean(pop(ord(1:mu0),:),1);
for k=2:K
    d=zeros(n0,1);
    for q=1:n0
        d(q)=min(sqrt(sum((means(1:k-1,:)-repmat(pop(q,:),k-1,1)).^2,2)));
    end
    [~,di]=max(d); means(k,:)=pop(di,:);
end
for k=1:K, C{k}=eye(D); end
nbCost=inf(K,1); nbVec=zeros(K,D); startCost=inf(K,1); evalCount=zeros(1,K);
for k=1:K
    d=sqrt(sum((pop-repmat(means(k,:),n0,1)).^2,2)); [~,di]=min(d);
    nbCost(k)=fitness(di); nbVec(k,:)=pop(di,:); startCost(k)=fitness(di);
end
shareW=baseW; rounds=0;
while used<budget
    rounds=rounds+1; nt=min(50,budget-used); counts=allocCounts(shareW,nt); K=numel(counts); Xn=cell(K,1); Vn=cell(K,1);
    for k=1:K
        n=counts(k); if n<=0, Xn{k}=zeros(0,D); Vn{k}=zeros(0,1); continue; end
        [B,L]=eig((C{k}+C{k}')/2); L=max(diag(L),1e-14); B=B*diag(sqrt(L));
        Z=randn(n,D); X=repmat(means(k,:),n,1)+sigma(k)*(Z*B'); X=reflectBounds(X,lb,ub);
        vals=zeros(n,1);
        for j=1:n
            vals(j)=f(X(j,:)); used=used+1; Best=UpdateBest(Best,X(j,:),vals(j)); T(used)=Best.Cost;
            if vals(j)<nbCost(k), nbCost(k)=vals(j); nbVec(k,:)=X(j,:); end
        end
        Xn{k}=X; Vn{k}=vals; evalCount(k)=evalCount(k)+n;
    end
    for k=1:K
        [means(k,:),C{k},pc(k,:),ps(k,:),sigma(k)]=updateNiche(means(k,:),C{k},pc(k,:),ps(k,:),sigma(k),Xn{k},Vn{k});
    end
    if strcmp(mode,'adaptive') && used>=window
        score=max(0,(startCost-nbCost)./max(abs(startCost),1));
        shareW=baseW+0.5*score(:)'; shareW=max(0.08,shareW); shareW=shareW/sum(shareW);
        startCost=nbCost; window=used+1000;
    end
end
info.Algorithm='MNC-CMA'; info.Evaluations=used; info.Rounds=rounds; info.NicheK=K;
info.NicheMeans=means; info.NicheBest=nbCost; info.NicheEval=evalCount; info.NicheShares=shareW;
info.Mode=mode; info.FinalSigma=sigma; info.Seconds=toc(clockStart);
end
function c=allocCounts(w,n)
w=w(:)'/sum(w); raw=w*n; c=floor(raw); rem=raw-c; [~,ord]=sort(rem,'descend');
for j=1:(n-sum(c)), c(ord(mod(j-1,numel(c))+1))=c(ord(mod(j-1,numel(c))+1))+1; end
end
function [m,C,pc,ps,sig]=updateNiche(m,C,pc,ps,sig,X,vals)
n=size(X,1); if n<4, return; end
mu=max(2,floor(n/2)); ww=log(mu+0.5)-log(1:mu)'; ww=ww/sum(ww); mueff=1/sum(ww.^2);
D=numel(m); cc=(4+mueff/D)/(D+4+2*mueff/D); cs=(mueff+2)/(D+mueff+5);
c1=2/((D+1.3)^2+mueff); cmu=min(1-c1,2*(mueff-2+1/mueff)/((D+2)^2+mueff));
damps=1+2*max(0,sqrt((mueff-1)/(D+1))-1)+cs; chiN=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
[~,ord]=sort(vals); sel=ord(1:mu); old=m; m=sum(ww.*X(sel,:),1); Y=(X(sel,:)-repmat(old,mu,1))/sig;
[E,L]=eig((C+C')/2); L=max(diag(L),1e-14); inv=E*diag(1./sqrt(L))*E';
ps=(1-cs)*ps+sqrt(cs*(2-cs)*mueff)*(inv*(m-old)')'/sig;
hsig=norm(ps)/sqrt(1-(1-cs)^2)/chiN < (1.4+2/(D+1));
pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*mueff)*(m-old)/sig;
C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(ww)*Y); C=(C+C')/2;
sig=sig*exp((cs/damps)*(norm(ps)/chiN-1)); sig=min(max(sig,1e-10),1e4);
end
function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
    low=X<lo; high=X>hi; if ~any(low(:)|high(:)), break; end
    X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
