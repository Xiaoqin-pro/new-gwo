function [Best,T,info]=CMA_TAIL_CEC(f,state,~,N,seed)
%CMA_TAIL_CEC  CMA-ES with covariance-preserving heavy-tailed proposal steps.
%   A small fraction of CMA draws is replaced by multivariate Student-t
%   steps.  The t scale is normalized to unit covariance, so rare large
%   jumps provide basin escape without changing the target covariance.
clockStart=tic;
D=size(state.initialPopulation,2); lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
lambda=max(4,round(N)); if isfield(state,'cmaLambda') && ~isempty(state.cmaLambda), lambda=max(4,round(state.cmaLambda)); end
mu=floor(lambda/2); assert(budget>=size(state.initialPopulation,1)); rng(seed,'twister');
w=log(mu+0.5)-log(1:mu)'; w=w/sum(w); mueff=1/sum(w.^2);
cc=(4+mueff/D)/(D+4+2*mueff/D); cs=(mueff+2)/(D+mueff+5);
c1=2/((D+1.3)^2+mueff); cmu=min(1-c1,2*(mueff-2+1/mueff)/((D+2)^2+mueff));
damps=1+2*max(0,sqrt((mueff-1)/(D+1))-1)+cs; chiN=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
C=eye(D); pc=zeros(1,D); ps=zeros(1,D); sigma=20;
pop=state.initialPopulation; n0=min(size(pop,1),budget);
T=nan(budget,1); Best.Cost=inf; fitness=zeros(n0,1);
for i=1:n0
    fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost;
end
[~,ord]=sort(fitness); xmean=sum(w(1:min(mu,n0)).*pop(ord(1:min(mu,n0)),:),1);
if n0<mu, xmean=pop(ord(1),:); end
mode='trigger'; if isfield(state,'cmaTailMode') && ~isempty(state.cmaTailMode), mode=lower(char(state.cmaTailMode)); end
baseFrac=0.03; tailFrac=0.18;
if isfield(state,'cmaTailBaseFraction') && ~isempty(state.cmaTailBaseFraction), baseFrac=max(0,min(0.8,state.cmaTailBaseFraction)); end
if isfield(state,'cmaTailFraction') && ~isempty(state.cmaTailFraction), tailFrac=max(0,min(0.8,state.cmaTailFraction)); end
nu=5; if isfield(state,'cmaTailNu') && ~isempty(state.cmaTailNu), nu=max(3,round(state.cmaTailNu)); end
stagWindow=12; if isfield(state,'cmaTailStagWindow') && ~isempty(state.cmaTailStagWindow), stagWindow=max(1,round(state.cmaTailStagWindow)); end
boostLength=4; if isfield(state,'cmaTailBoostLength') && ~isempty(state.cmaTailBoostLength), boostLength=max(1,round(state.cmaTailBoostLength)); end
minProgress=0.05; maxProgress=0.95; selTol=1e-10;
if isfield(state,'cmaTailMinProgress') && ~isempty(state.cmaTailMinProgress), minProgress=state.cmaTailMinProgress; end
if isfield(state,'cmaTailMaxProgress') && ~isempty(state.cmaTailMaxProgress), maxProgress=state.cmaTailMaxProgress; end
if isfield(state,'cmaTailSelTol') && ~isempty(state.cmaTailSelTol), selTol=max(0,state.cmaTailSelTol); end
stag=0; boostLeft=0; previousBest=Best.Cost; selRef=inf;
tailGenerated=0; tailSelected=0; triggers=0; rounds=0;
info.Evaluations=n0; info.Rounds=0; info.InitialCost=Best.Cost;
while info.Evaluations<budget
    rounds=rounds+1;
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); B=B*diag(sqrt(lam));
    Z=randn(lambda,D); X=repmat(xmean,lambda,1)+sigma*(Z*B');
    tailMask=false(lambda,1); useTail=false; frac=0;
    progress=info.Evaluations/budget; inWindow=(progress>=minProgress && progress<=maxProgress);
    if strcmp(mode,'always')
        useTail=tailFrac>0; frac=tailFrac;
    elseif strcmp(mode,'random')
        useTail=tailFrac>0; frac=tailFrac;
    elseif strcmp(mode,'trigger')
        if boostLeft>0 || stag>=stagWindow
            if boostLeft<=0, boostLeft=boostLength; triggers=triggers+1; end
            useTail=inWindow; frac=tailFrac;
        elseif baseFrac>0
            useTail=inWindow; frac=baseFrac;
        end
    end
    if useTail
        nTail=min(lambda,round(frac*lambda)); tailMask(1:nTail)=true;
        if strcmp(mode,'random')
            X(1:nTail,:)=repmat(lb,nTail,1)+rand(nTail,D).*repmat(ub-lb,nTail,1);
        else
            for k=1:nTail
                W=sum(randn(nu,1).^2);
                Z(k,:)=Z(k,:)*sqrt((nu-2)/max(W,realmin));
                X(k,:)=xmean+sigma*(Z(k,:)*B');
            end
        end
        tailGenerated=tailGenerated+nTail;
    end
    X=reflectBounds(X,lb,ub);
    count=min(lambda,budget-info.Evaluations); X=X(1:count,:); tailMask=tailMask(1:count);
    vals=zeros(count,1);
    for i=1:count
        vals(i)=f(X(i,:)); T(info.Evaluations+i)=Best.Cost;
    end
    for i=1:count
        Best=UpdateBest(Best,X(i,:),vals(i)); T(info.Evaluations+i)=Best.Cost;
    end
    info.Evaluations=info.Evaluations+count; info.Rounds=rounds;
    if count<mu || info.Evaluations>=budget, break; end
    [~,ord]=sort(vals); sel=ord(1:mu); tailSelected=tailSelected+sum(tailMask(sel));
    xold=xmean; xmean=sum(w.*X(sel,:),1);
    Y=(X(sel,:)-repmat(xold,mu,1))/sigma;
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); invsqrt=B*diag(1./sqrt(lam))*B';
    ps=(1-cs)*ps+sqrt(cs*(2-cs)*mueff)*(invsqrt*(xmean-xold)')'/sigma;
    hsig=norm(ps)/sqrt(1-(1-cs)^(2*info.Rounds))/chiN < (1.4+2/(D+1));
    pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*mueff)*(xmean-xold)/sigma;
    C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(w)*Y); C=(C+C')/2;
    [Ec,Lc]=eig(C); Lc=max(diag(Lc),1e-12); C=Ec*diag(Lc)*Ec'; C=(C+C')/2;
    sigma=sigma*exp((cs/damps)*(norm(ps)/chiN-1)); sigma=min(max(sigma,1e-10),1e4);
    selMedian=median(vals(sel));
    if isinf(selRef), selImproved=true; else, selImproved=selMedian<selRef-selTol*max(1,abs(selRef)); end
    if selImproved, selRef=selMedian; end
    if (Best.Cost < previousBest-1e-12*max(1,abs(previousBest))) || selImproved
        stag=0; boostLeft=0; previousBest=Best.Cost;
    else
        stag=stag+1; if boostLeft>0, boostLeft=boostLeft-1; end
    end
end
info.Algorithm='CMA-TAIL'; info.Seed=seed; info.Sigma=sigma; info.PopulationSize=lambda;
info.FinalMean=xmean; info.FinalCovariance=C; info.Seconds=toc(clockStart);
info.CmaTailMode=mode; info.CmaTailFraction=tailFrac; info.CmaTailBaseFraction=baseFrac;
info.CmaTailGenerated=tailGenerated; info.CmaTailSelected=tailSelected;
info.CmaTailSelectedRate=tailSelected/max(tailGenerated,1); info.CmaTailTriggers=triggers;
info.CmaTailStagnation=stag; info.CmaTailNu=nu;
info.FinalCMAState=struct('Mean',xmean,'C',C,'Sigma',sigma,'PC',pc,'PS',ps, ...
    'Generation',info.Rounds,'Best',Best,'Evaluations',info.Evaluations);
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
