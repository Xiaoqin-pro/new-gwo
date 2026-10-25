function [Best,T,info]=SPACMA_CEC(f,state,~,N,seed)
%SPACMA_CEC  Dual-class DE/CMA hybrid with improvement-credit scheduling.
%   Each generation assigns every parent to either a rank-biased DE class or
%   a covariance-sampled CMA class.  The class probability memory is updated
%   from the realized improvement mass of the two classes.  All candidates
%   are evaluated exactly once.
clockStart=tic;
pop=state.initialPopulation; sizepop=min(round(N),size(pop,1)); pop=pop(1:sizepop,:); D=size(pop,2);
initialSize=sizepop; minSize=4; lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(sizepop>=4 && budget>=sizepop); rng(seed,'twister');
pBestRate=0.11; archiveRate=1.4; memorySize=5; rankK=3; lRate=0.80;
classMode='adaptive'; if isfield(state,'spaClassMode') && ~isempty(state.spaClassMode), classMode=lower(char(state.spaClassMode)); end
initClass=0.5; if isfield(state,'spaInitClass') && ~isempty(state.spaInitClass), initClass=min(0.8,max(0.2,state.spaInitClass)); end
progressGate=0.0; if isfield(state,'spaProgressBias') && ~isempty(state.spaProgressBias), progressGate=max(0,min(0.4,state.spaProgressBias)); end
progressWindow=5000; if isfield(state,'spaProgressWindow') && ~isempty(state.spaProgressWindow), progressWindow=max(100,round(state.spaProgressWindow)); end
progressTol=1e-4; if isfield(state,'spaProgressTol') && ~isempty(state.spaProgressTol), progressTol=max(0,state.spaProgressTol); end
T=nan(budget,1); fitness=zeros(sizepop,1); Best.Cost=inf; used=0;
for i=1:sizepop
    fitness(i)=f(pop(i,:)); used=used+1; Best=UpdateBest(Best,pop(i,:),fitness(i)); T(used)=Best.Cost;
end
memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1); memoryClass=initClass*ones(memorySize,1); memoryPos=1;
archive=zeros(0,D); archiveF=zeros(0,1); archiveCap=round(archiveRate*sizepop);
[~,ord]=sort(fitness); mu=max(2,floor(sizepop/2)); weights=log(mu+0.5)-log(1:mu)'; weights=weights/sum(weights);
xmean=sum(weights.*pop(ord(1:mu),:),1); sigma=20;
if isfield(state,'spaSigma0') && ~isempty(state.spaSigma0), sigma=state.spaSigma0; end
C=eye(D); pc=zeros(1,D); ps=zeros(1,D); B=eye(D); eigD=ones(1,D); invsqrtC=eye(D); eigeneval=0;
rounds=0; hybridOn=true; deEval=0; cmaEval=0; deSuccess=0; cmaSuccess=0; classTrace=zeros(0,2);
progressBias=0; recentProgress=NaN; progressStart=used; progressMean=0; progressUpdates=0;
while used<budget
    rounds=rounds+1; [~,order]=sort(fitness);
    % Modified worst-slot regeneration from the leading search direction.
    if sizepop>=5 && used<budget/2
        nRep=max(1,floor(0.01*sizepop)); worst=order(end-nRep+1:end);
        direction=pop(order(1),:)-pop(order(2),:);
        pop(worst,:)=repmat(pop(order(1),:),nRep,1)+rand(nRep,D).*repmat(direction,nRep,1);
        pop=BoundConstraint(pop,pop(1:sizepop,:),lb,ub);
    end
    memIndex=ceil(memorySize*rand(sizepop,1)); muF=memoryF(memIndex); muCR=memoryCR(memIndex); muClass=memoryClass(memIndex);
    CR=muCR+0.1*randn(sizepop,1); CR(muCR==-1)=0; CR=max(0,min(1,CR));
    if used<=budget/2
        F=0.5+0.1*rand(sizepop,1);
    else
        F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5)); bad=find(F<=0);
        while ~isempty(bad)
            F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5)); bad=find(F<=0);
        end
    end
    F=min(1,F);
    if strcmp(classMode,'adaptive')
        if progressGate>0
            pEff=min(0.8,max(0.2,muClass+progressBias));
        else
            pEff=muClass;
        end
        isDE=pEff>=rand(sizepop,1);
    elseif strcmp(classMode,'random'), isDE=rand(sizepop,1)<0.5;
    elseif strcmp(classMode,'de'), isDE=true(sizepop,1);
    elseif strcmp(classMode,'cma'), isDE=false(sizepop,1);
    else, isDE=true(sizepop,1);
    end
    if ~hybridOn, isDE(:)=true; end
    pool=[pop;archive]; poolF=[fitness;archiveF]; [r1,r2]=RandomParents(sizepop,size(pool,1));
    pCount=max(round(pBestRate*sizepop),2); pIndex=max(1,ceil(rand(1,sizepop)*pCount)); pbest=pop(order(pIndex),:);
    rankWeights=rankK*(sizepop-(1:sizepop))+1; rankWeights=rankWeights/sum(rankWeights);
    rankPick=Roulette(rankWeights,sizepop); donor=pop(order(rankPick),:);
    mutant=zeros(sizepop,D);
    if any(isDE)
        idx=find(isDE);
        mutant(idx,:)=pop(idx,:)+F(idx).*(pbest(idx,:)-pop(idx,:)+donor(idx,:)-pool(r2(idx),:));
    end
    if any(~isDE) && hybridOn
        idx=find(~isDE);
        transform=B*diag(eigD);
        mutant(idx,:)=repmat(xmean,numel(idx),1)+sigma*(randn(numel(idx),D)*transform');
    end
    mutant=BoundConstraint(mutant,pop,lb,ub);
    jr=floor(rand(sizepop,1)*D)+1; crs=rand(sizepop,D)<=CR; crs(sub2ind([sizepop D],(1:sizepop)',jr))=true;
    trial=pop; trial(crs)=mutant(crs); trial=BoundConstraint(trial,pop,lb,ub);
    count=min(sizepop,budget-used); values=fitness; oldFitness=fitness;
    for i=1:count
        values(i)=f(trial(i,:)); used=used+1; Best=UpdateBest(Best,trial(i,:),values(i)); T(used)=Best.Cost;
    end
    improved=false(sizepop,1); improved(1:count)=values(1:count)<oldFitness(1:count);
    gain=max(oldFitness-values,0); gain(~improved)=0;
    deEval=deEval+sum(isDE(1:count)); cmaEval=cmaEval+sum(~isDE(1:count));
    deSuccess=deSuccess+sum(improved & isDE); cmaSuccess=cmaSuccess+sum(improved & ~isDE);
    if any(improved(1:count))
        [archive,archiveF]=UpdateArchive(archive,archiveF,pop(improved,:),oldFitness(improved),archiveCap);
    end
    goodF=F(improved); goodCR=CR(improved); goodGain=gain(improved);
    if ~isempty(goodF) && sum(goodGain)>0
        w=goodGain/sum(goodGain);
        memoryF(memoryPos)=sum(w.*goodF.^2)/max(sum(w.*goodF),realmin);
        if max(goodCR)==0 || memoryCR(memoryPos)==-1, memoryCR(memoryPos)=-1;
        else, memoryCR(memoryPos)=sum(w.*goodCR.^2)/max(sum(w.*goodCR),realmin); end
        if strcmp(classMode,'adaptive') && hybridOn
            gainDE=sum(gain(improved & isDE)); gainCMA=sum(gain(improved & ~isDE));
            if gainDE+gainCMA>0
                observed=gainDE/(gainDE+gainCMA);
                memoryClass(memoryPos)=lRate*memoryClass(memoryPos)+(1-lRate)*observed;
            end
            memoryClass(memoryPos)=min(0.8,max(0.2,memoryClass(memoryPos)));
        end
        memoryPos=mod(memoryPos,memorySize)+1;
    end
    pop(improved,:)=trial(improved,:); fitness(improved)=values(improved);
    classTrace(end+1,:)=[sum(isDE(1:count)),sum(~isDE(1:count))];
    if used-progressStart>=progressWindow
        base=T(max(1,used-progressWindow)); recentProgress=(base-Best.Cost)/max(1,abs(base));
        if progressGate>0
            if recentProgress<progressTol, progressBias=progressGate; else, progressBias=-progressGate; end
        end
        progressMean=progressMean+progressBias; progressUpdates=progressUpdates+1; progressStart=used;
    end
    if hybridOn
        mu=max(2,floor(sizepop/2)); weights=log(mu+0.5)-log(1:mu)'; weights=weights/sum(weights); muEff=1/sum(weights.^2);
        cc=(4+muEff/D)/(D+4+2*muEff/D); cs=(muEff+2)/(D+muEff+5);
        c1=2/((D+1.3)^2+muEff); cmu=min(1-c1,2*(muEff-2+1/muEff)/((D+2)^2+muEff));
        damps=1+2*max(0,sqrt((muEff-1)/(D+1))-1)+cs; chiN=sqrt(D)*(1-1/(4*D)+1/(21*D^2));
        [~,o]=sort(fitness); sel=o(1:mu); xold=xmean; xmean=sum(weights.*pop(sel,:),1);
        ps=(1-cs)*ps+sqrt(cs*(2-cs)*muEff)*(invsqrtC*(xmean-xold)')'/sigma;
        hsig=norm(ps)/sqrt(1-(1-cs)^(2*rounds))/chiN < (1.4+2/(D+1));
        pc=(1-cc)*pc+double(hsig)*sqrt(cc*(2-cc)*muEff)*(xmean-xold)/sigma;
        Y=(pop(sel,:)-repmat(xold,mu,1))/sigma;
        C=(1-c1-cmu)*C+c1*(pc'*pc+double(~hsig)*cc*(2-cc)*C)+cmu*(Y'*diag(weights)*Y); C=(C+C')/2;
        sigma=sigma*exp((cs/damps)*(norm(ps)/chiN-1)); sigma=min(max(sigma,1e-10),1e4);
        if rounds==1 || used-eigeneval>max(2,round(sizepop/(c1+cmu)/D/10))
            eigeneval=used; [B,L]=eig(C); L=max(diag(L),1e-14); eigD=sqrt(L)'; B=B; invsqrtC=B*diag(1./eigD)*B';
            if any(~isfinite(C(:))) || any(~isfinite(B(:))), hybridOn=false; C=eye(D); B=eye(D); eigD=ones(1,D); invsqrtC=eye(D); end
        end
    end
    planned=max(minSize,round(initialSize+(minSize-initialSize)*used/budget));
    if sizepop>planned
        [~,o]=sort(fitness); pop=pop(o(1:planned),:); fitness=fitness(o(1:planned)); sizepop=planned;
        archiveCap=round(archiveRate*sizepop);
        if size(archive,1)>archiveCap, keep=randperm(size(archive,1),archiveCap); archive=archive(keep,:); archiveF=archiveF(keep); end
    end
end
info.Algorithm='SPACMA'; info.Evaluations=used; info.Rounds=rounds; info.FinalPopulation=pop; info.FinalFitness=fitness;
info.FinalArchive=archive; info.ClassMode=classMode; info.ClassProb=memoryClass; info.ClassProbMean=mean(memoryClass);
info.DEEval=deEval; info.CMAEval=cmaEval; info.DESuccess=deSuccess; info.CMASuccess=cmaSuccess; info.HybridOn=double(hybridOn);
info.ProgressBias=progressBias; info.ProgressBiasMean=progressMean/max(progressUpdates,1); info.RecentProgress=recentProgress; info.ProgressGate=progressGate;
info.FinalMean=xmean; info.Sigma=sigma; info.FinalCMAState=struct('Mean',xmean,'C',C,'Sigma',sigma,'PC',pc,'PS',ps,'Generation',rounds,'Best',Best,'Evaluations',used);
info.Seconds=toc(clockStart);
end
function [r1,r2]=RandomParents(n,poolSize)
r0=1:n; r1=floor(rand(1,n)*n)+1; bad=r1==r0;
while any(bad), r1(bad)=floor(rand(1,sum(bad))*n)+1; bad=r1==r0; end
r2=floor(rand(1,n)*poolSize)+1; bad=r2==r0 | r2==r1;
while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0 | r2==r1; end
end
function idx=Roulette(w,n)
edges=cumsum(w(:))'; u=rand(1,n); idx=zeros(1,n);
for i=1:n, idx(i)=find(u(i)<=edges,1,'first'); end
idx=max(1,min(numel(w),idx));
end
function X=BoundConstraint(X,pop,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); P=pop(1:size(X,1),:);
out=X<lo; X(out)=(P(out)+lo(out))/2; out=X>hi; X(out)=(P(out)+hi(out))/2;
end
function [archive,archiveF]=UpdateArchive(archive,archiveF,newPop,newF,cap)
if isempty(newPop) || cap<=0, return; end
popAll=[archive;newPop]; funAll=[archiveF;newF]; [popAll,ia]=unique(popAll,'rows','stable'); funAll=funAll(ia);
if size(popAll,1)>cap, keep=randperm(size(popAll,1),cap); popAll=popAll(keep,:); funAll=funAll(keep); end
archive=popAll; archiveF=funAll;
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
