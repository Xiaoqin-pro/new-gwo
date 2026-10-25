function [Best,T,info]=CMA_DE_CEC(f,state,~,N,seed)
%CMA_DE_CEC  CMA-ES with stagnation-triggered DE displacement proposals.
%   The covariance learning loop remains CMA.  During stagnation, a fraction
%   of Gaussian samples is recentred by differential-evolution displacements
%   drawn from the verified recent population.  Every candidate is evaluated
%   exactly once and the successful realized steps enter the same covariance
%   update.  CEoff gives ordinary CMA; random mode is the direction control.

clockStart=tic;
D=size(state.initialPopulation,2);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
lambda=max(4,round(N));
if isfield(state,'cmaLambda') && ~isempty(state.cmaLambda), lambda=max(4,round(state.cmaLambda)); end
mu=floor(lambda/2);
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
sigma=20;
pop=state.initialPopulation;
n0=min(size(pop,1),budget);
T=nan(budget,1); Best.Cost=inf;
fitness=zeros(n0,1);
for i=1:n0
    fitness(i)=f(pop(i,:));
    Best=UpdateBest(Best,pop(i,:),fitness(i));
    T(i)=Best.Cost;
end
[~,ord]=sort(fitness);
xmean=sum(w(1:min(mu,n0)).*pop(ord(1:min(mu,n0)),:),1);
if n0<mu, xmean=pop(ord(1),:); end

mixMode='trigger';
if isfield(state,'cmaMixMode') && ~isempty(state.cmaMixMode), mixMode=lower(char(state.cmaMixMode)); end
rho=0.25;
if isfield(state,'cmaMixFraction') && ~isempty(state.cmaMixFraction), rho=state.cmaMixFraction; end
rho=max(0,min(0.8,rho));
baseRho=0.02; if isfield(state,'cmaMixBaseFraction') && ~isempty(state.cmaMixBaseFraction), baseRho=max(0,min(0.8,state.cmaMixBaseFraction)); end
stagWindow=10;
if isfield(state,'cmaStagWindow') && ~isempty(state.cmaStagWindow), stagWindow=max(1,round(state.cmaStagWindow)); end
boostLength=4;
if isfield(state,'cmaBoostLength') && ~isempty(state.cmaBoostLength), boostLength=max(1,round(state.cmaBoostLength)); end
deF=0.50; gammaMix=0.35; mixMinProgress=0.08; mixMaxProgress=0.80; mixStepCap=1.0; selProgressTol=1e-10; mixPeriod=5; primeList=primes(300); primeList=primeList(1:D); haltonIndex=0;
if any(strcmp(mixMode,{'halton','halton_success','halton_burst'})), haltonIndex=mod(seed*7919,100000)+1; end
scoutSuccessThreshold=0.20; if isfield(state,'cmaScoutSuccessThreshold') && ~isempty(state.cmaScoutSuccessThreshold), scoutSuccessThreshold=max(0,min(1,state.cmaScoutSuccessThreshold)); end
scoutCovUpdate=true; if isfield(state,'cmaScoutCovUpdate') && ~isempty(state.cmaScoutCovUpdate), scoutCovUpdate=logical(state.cmaScoutCovUpdate); end
srEMA=1; triggerAt=stagWindow;
if isfield(state,'cmaDEF') && ~isempty(state.cmaDEF), deF=max(0,state.cmaDEF); end
if isfield(state,'cmaMixScale') && ~isempty(state.cmaMixScale), gammaMix=max(0,state.cmaMixScale); end
if isfield(state,'cmaMixMinProgress') && ~isempty(state.cmaMixMinProgress), mixMinProgress=state.cmaMixMinProgress; end
if isfield(state,'cmaMixMaxProgress') && ~isempty(state.cmaMixMaxProgress), mixMaxProgress=state.cmaMixMaxProgress; end
if isfield(state,'cmaMixStepCap') && ~isempty(state.cmaMixStepCap), mixStepCap=max(0,state.cmaMixStepCap); end
if isfield(state,'cmaSelProgressTol') && ~isempty(state.cmaSelProgressTol), selProgressTol=max(0,state.cmaSelProgressTol); end
if isfield(state,'cmaMixPeriod') && ~isempty(state.cmaMixPeriod), mixPeriod=max(1,round(state.cmaMixPeriod)); end
historyCap=max(2*lambda,4*lambda);
lastX=pop; lastF=fitness;
histX=pop; histF=fitness;
stag=0; boostLeft=0; previousBest=Best.Cost; selRef=inf;
mixGenerated=0; mixSelected=0; mixTrace=zeros(0,9);
triggerCount=0; rounds=0; currentRho=0;
info.Evaluations=n0; info.Rounds=0; info.InitialCost=Best.Cost;

while info.Evaluations<budget
    rounds=rounds+1;
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); B=B*diag(sqrt(lam));
    Z=randn(lambda,D);
    X=repmat(xmean,lambda,1)+sigma*(Z*B');
    mixed=false(lambda,1); nMix=0;
    progress=info.Evaluations/budget; inMixWindow=(progress>=mixMinProgress && progress<=mixMaxProgress);
    useMix=false;
    if strcmp(mixMode,'always') || strcmp(mixMode,'random') || strcmp(mixMode,'permuted') || strcmp(mixMode,'maximin') || strcmp(mixMode,'opposition') || strcmp(mixMode,'halton')
        useMix=rho>0;
        currentRho=rho;
    elseif strcmp(mixMode,'periodic')
        useMix=inMixWindow && mod(rounds,mixPeriod)==0 && rho>0;
        currentRho=rho;
    elseif strcmp(mixMode,'trigger')
        useMix=inMixWindow && (stag>=stagWindow || boostLeft>0) && rho>0;
        if useMix && boostLeft<=0, boostLeft=boostLength; triggerCount=triggerCount+1; end
        currentRho=rho;
    elseif strcmp(mixMode,'maximin_trigger') || strcmp(mixMode,'random_trigger')
        useMix=inMixWindow;
        currentRho=baseRho;
        if stag>=stagWindow || boostLeft>0
            if boostLeft<=0, boostLeft=boostLength; triggerCount=triggerCount+1; end
            currentRho=rho;
        end
    elseif strcmp(mixMode,'random_success') || strcmp(mixMode,'halton_success')
        useMix=inMixWindow && srEMA<scoutSuccessThreshold;
        currentRho=rho;
    elseif strcmp(mixMode,'random_burst') || strcmp(mixMode,'halton_burst')
        if boostLeft<=0 && stag>=triggerAt
            boostLeft=boostLength; triggerAt=stag+stagWindow; triggerCount=triggerCount+1;
        end
        useMix=inMixWindow && boostLeft>0;
        currentRho=rho;
    end
    if useMix
        nMix=min(lambda,round(currentRho*lambda));
        mixed(1:nMix)=true;
        poolX=[lastX;histX]; poolF=[lastF;histF];
        poolSize=size(poolX,1);
        pCount=max(2,round(0.11*poolSize));
        [~,poolOrder]=sort(poolF);
        bestPool=poolOrder(1:min(pCount,poolSize));
        chosenCentres=zeros(0,D);
        for k=1:nMix
            if strcmp(mixMode,'random') || strcmp(mixMode,'random_trigger') || strcmp(mixMode,'random_success') || strcmp(mixMode,'random_burst')
                centre=lb+rand(1,D).*(ub-lb);
            elseif strcmp(mixMode,'halton') || strcmp(mixMode,'halton_success') || strcmp(mixMode,'halton_burst')
                haltonIndex=haltonIndex+1; u=HaltonVector(haltonIndex,primeList); centre=lb+u.*(ub-lb);
            elseif strcmp(mixMode,'opposition')
                centre=lb+ub-Best.Vector+0.1*sigma*randn(1,D);
                centre=reflectBounds(centre,lb,ub);
            elseif strcmp(mixMode,'maximin') || strcmp(mixMode,'maximin_trigger')
                nProposal=8; candidates=repmat(lb,nProposal,1)+rand(nProposal,D).*repmat(ub-lb,nProposal,1);
                ref=[poolX;chosenCentres]; score=zeros(nProposal,1);
                for q=1:nProposal
                    dd=ref-repmat(candidates(q,:),size(ref,1),1); score(q)=min(sqrt(sum(dd.^2,2)));
                end
                [~,mi]=max(score); centre=candidates(mi,:); chosenCentres(end+1,:)=centre;
            else
                pb=bestPool(randi(numel(bestPool)));
                i=randi(poolSize);
                r1=randi(poolSize);
                while r1==i, r1=randi(poolSize); end
                r2=randi(poolSize);
                while r2==i || r2==r1, r2=randi(poolSize); end
                step=deF*(poolX(pb,:)-poolX(i,:))+deF*(poolX(r1,:)-poolX(r2,:));
                if strcmp(mixMode,'permuted'), step=step(randperm(D)); end
                if mixStepCap>0 && isfinite(mixStepCap)
                    cap=mixStepCap*sigma*sqrt(D); sn=norm(step);
                    if sn>cap && sn>0, step=step*(cap/sn); end
                end
                centre=xmean+gammaMix*step;
                centre=reflectBounds(centre,lb,ub);
            end
            X(k,:)=centre+sigma*(Z(k,:)*B');
        end
        mixGenerated=mixGenerated+nMix;
    end
    X=reflectBounds(X,lb,ub);
    count=min(lambda,budget-info.Evaluations); X=X(1:count,:); mixed=mixed(1:count);
    vals=zeros(count,1);
    for i=1:count
        vals(i)=f(X(i,:));
        T(info.Evaluations+i)=Best.Cost;
    end
    for i=1:count
        Best=UpdateBest(Best,X(i,:),vals(i));
        T(info.Evaluations+i)=Best.Cost;
    end
    info.Evaluations=info.Evaluations+count; info.Rounds=rounds;
    if count<mu || info.Evaluations>=budget, break; end

    [~,ord]=sort(vals);
    if ~scoutCovUpdate && any(mixed)
        gaussIdx=find(~mixed); [~,gaussOrd]=sort(vals(gaussIdx)); sel=gaussIdx(gaussOrd(1:min(mu,numel(gaussIdx))));
    else
        sel=ord(1:mu);
    end
    muSel=numel(sel); if muSel<mu, wSel=log(muSel+0.5)-log(1:muSel)'; wSel=wSel/sum(wSel); else, wSel=w; end
    mixSelected=mixSelected+sum(mixed(sel));
    xold=xmean; xmean=sum(wSel.*X(sel,:),1);
    Y=(X(sel,:)-repmat(xold,muSel,1))/sigma;
    [B,lam]=eig((C+C')/2); lam=max(diag(lam),1e-14); invsqrt=B*diag(1./sqrt(lam))*B';
    ps=(1-cs)*ps+sqrt(cs*(2-cs)*mueff)*(invsqrt*(xmean-xold)')'/sigma;
    hsig=norm(ps)/sqrt(1-(1-cs)^(2*info.Rounds))/chiN < (1.4+2/(D+1));
    pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*mueff)*(xmean-xold)/sigma;
    C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(wSel)*Y);
    C=(C+C')/2;
    [Ec,Lc]=eig(C); Lc=max(diag(Lc),1e-12); C=Ec*diag(Lc)*Ec'; C=(C+C')/2;
    sigma=sigma*exp((cs/damps)*(norm(ps)/chiN-1));
    sigma=min(max(sigma,1e-10),1e4);

    improved=vals<lastF; srEMA=0.9*srEMA+0.1*(sum(improved)/max(numel(improved),1));
    lastX=X; lastF=vals; selMedian=median(vals(sel));
    if isinf(selRef)
        selImproved=true;
    else
        selImproved=selMedian < selRef - selProgressTol*max(1,abs(selRef));
    end
    if selImproved, selRef=selMedian; end
    condC=cond((C+C')/2); mixTrace(end+1,:)=[rounds,info.Evaluations,stag,nMix,sigma,Best.Cost,selMedian,double(useMix),condC];
    histX=[histX;X]; histF=[histF;vals];
    if size(histX,1)>historyCap
        histX=histX(end-historyCap+1:end,:); histF=histF(end-historyCap+1:end);
    end

    if (Best.Cost < previousBest - 1e-12*max(1,abs(previousBest))) || selImproved
        stag=0; boostLeft=0; triggerAt=stagWindow; previousBest=Best.Cost;
    else
        stag=stag+1;
        if boostLeft>0, boostLeft=boostLeft-1; end
    end
end

info.Algorithm='CMA-DE-MIX'; info.Seed=seed; info.Sigma=sigma; info.PopulationSize=lambda;
info.FinalMean=xmean; info.FinalCovariance=C; info.Seconds=toc(clockStart);
info.CmaMixMode=mixMode; info.CmaMixFraction=rho; info.CmaMixBaseFraction=baseRho; info.CmaMixGenerated=mixGenerated;
info.CmaMixSelected=mixSelected; info.CmaMixSelectedRate=mixSelected/max(mixGenerated,1);
info.CmaMixTriggers=triggerCount; info.CmaStagnationGeneration=stag; info.CmaStagWindow=stagWindow; info.CmaMixPeriod=mixPeriod; info.CmaScoutSuccessEMA=srEMA; info.CmaScoutThreshold=scoutSuccessThreshold; info.CmaScoutCovUpdate=double(scoutCovUpdate);
info.CmaMixTrace=mixTrace;
info.FinalCMAState=struct('Mean',xmean,'C',C,'Sigma',sigma,'PC',pc,'PS',ps, ...
    'Generation',info.Rounds,'Best',Best,'Evaluations',info.Evaluations);
end

function u=HaltonVector(index,primeList)
D=numel(primeList); u=zeros(1,D);
for j=1:D
    i=index; f=1; r=0; p=primeList(j);
    while i>0
        f=f/p; r=r+f*mod(i,p); i=floor(i/p);
    end
    u(j)=r;
end
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



