function [Best,T,info]=NMLSHADE(f,state,~,N,seed)
%NMLSHADE  Niche-migration L-SHADE.
%   L-SHADE is left intact during normal progress.  A verified niche bank is
%   maintained from real evaluations.  When a meaningful-progress window
%   expires, the worst individuals are migrated to certified, spatially
%   separated bank solutions (zero additional FE).  The bank is never used
%   for fitness ranking unless every stored value came from a real evaluation.
%
%   state.migMode:
%     'off'            : bitwise-equivalent to LSHADE_CEC
%     'periodic_niche' : niche bank migration every fixed FE interval
%     'plateau_random' : same plateau trigger, random history reservoir
%     'plateau_niche'  : full mechanism
clockStart=tic;
pop=state.initialPopulation;
D=size(pop,2); sizepop=N; initialSize=sizepop; minSize=4;
pBestRate=0.11; archiveRate=1.4; memorySize=5;
if isfield(state,'lshadeProfile') && strcmp(state.lshadeProfile,'standard')
    archiveRate=2.6; memorySize=6;
end
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(sizepop>=4 && budget>=sizepop);
rng(seed,'twister');

migMode='off';
if isfield(state,'migMode') && ~isempty(state.migMode), migMode=lower(char(state.migMode)); end
isOff=strcmp(migMode,'off');
isNiche=~isOff && ~strcmp(migMode,'plateau_random');
isPeriodic=strcmp(migMode,'periodic_niche');
isPlateau=~isOff && ~isPeriodic;
migFrac=0.25; bankCap=32; bankSep=0.02;
progressWindowFrac=0.05; plateauTol=5e-4; periodicFrac=0.10;
if isfield(state,'migFrac') && ~isempty(state.migFrac), migFrac=state.migFrac; end
if isfield(state,'migBankCap') && ~isempty(state.migBankCap), bankCap=state.migBankCap; end
if isfield(state,'migBankSep') && ~isempty(state.migBankSep), bankSep=state.migBankSep; end
if isfield(state,'migProgressFrac') && ~isempty(state.migProgressFrac), progressWindowFrac=state.migProgressFrac; end
if isfield(state,'migPlateauTol') && ~isempty(state.migPlateauTol), plateauTol=state.migPlateauTol; end
if isfield(state,'migPeriodicFrac') && ~isempty(state.migPeriodicFrac), periodicFrac=state.migPeriodicFrac; end
bankCap=max(4,round(bankCap)); migFrac=min(0.8,max(0,migFrac));
progressWindow=max(2*N,round(progressWindowFrac*budget));
periodicEvery=max(2*N,round(periodicFrac*budget));
span=max(norm(ub-lb),eps);

fitness=zeros(sizepop,1); T=nan(budget,1); Best.Cost=inf;
for i=1:sizepop
    fitness(i)=f(pop(i,:));
    Best=UpdateBest(Best,pop(i,:),fitness(i));
    T(i)=Best.Cost;
end
info.Evaluations=sizepop; info.InitialCost=Best.Cost;
info.InitialPopulation=pop; info.FirstImprovementEvaluation=NaN;
info.PopulationHistory=sizepop; info.ArchiveSizeHistory=0;
memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1); memoryPos=1;
archive=zeros(0,D); archiveCapacity=round(archiveRate*sizepop);

nicheX=zeros(0,D); nicheF=zeros(0,1);
histX=zeros(0,D); histF=zeros(0,1);
nMigTrig=0; nMigRounds=0; nMigrants=0; nMigBetter=0; migTrace=zeros(0,3);
stride=max(1,floor(budget/max(bankCap,1)));
if ~isOff
    [~,ord0]=sort(fitness);
    nSeed=min(N,max(4,round(0.5*N)));
    for ii=1:nSeed
        [nicheX,nicheF]=bankAdmit(nicheX,nicheF,pop(ord0(ii),:), ...
            fitness(ord0(ii)),bankCap,bankSep,span);
    end
    histX=pop; histF=fitness;
end

winStartFE=info.Evaluations; winBest=Best.Cost; nextPeriodic=info.Evaluations+periodicEvery;
while info.Evaluations<budget
    [~,order]=sort(fitness);
    memoryIndex=ceil(memorySize*rand(sizepop,1));
    muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
    CR=muCR+0.1*randn(sizepop,1); CR(muCR==-1)=0; CR=max(0,min(1,CR));
    F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5)); bad=find(F<=0);
    while ~isempty(bad)
        F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5)); bad=find(F<=0);
    end
    F=min(1,F);

    pool=[pop;archive];
    [r1,r2]=RandomParents(sizepop,size(pool,1));
    pCount=max(round(pBestRate*sizepop),2);
    pIndex=max(1,ceil(rand(1,sizepop)*pCount));
    pbest=pop(order(pIndex),:);
    mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
    lowB=repmat(lb,sizepop,1); upB=repmat(ub,sizepop,1);
    outside=mutant<lowB; mutant(outside)=(pop(outside)+lowB(outside))/2;
    outside=mutant>upB; mutant(outside)=(pop(outside)+upB(outside))/2;
    mask=rand(sizepop,D)>CR;
    jrand=sub2ind([sizepop D],(1:sizepop)',floor(rand(sizepop,1)*D)+1);
    mask(jrand)=false;
    trial=mutant; trial(mask)=pop(mask);

    count=min(sizepop,budget-info.Evaluations);
    values=fitness; medFit=median(fitness(1:sizepop));
    if ~isOff
        for i=1:count
            values(i)=f(trial(i,:));
            info.Evaluations=info.Evaluations+1;
            if values(i)<Best.Cost
                Best.Vector=trial(i,:); Best.Cost=values(i);
                if isnan(info.FirstImprovementEvaluation), info.FirstImprovementEvaluation=info.Evaluations; end
            end
            T(info.Evaluations)=Best.Cost;
            if values(i)<=medFit
                [nicheX,nicheF]=bankAdmit(nicheX,nicheF,trial(i,:),values(i),bankCap,bankSep,span);
            end
            if ~isOff && values(i)<=medFit
                slot=mod(floor((info.Evaluations-1)/stride),bankCap)+1;
                histX(slot,:)=trial(i,:); histF(slot,1)=values(i);
            end
        end
    else
        for i=1:count
            values(i)=f(trial(i,:)); info.Evaluations=info.Evaluations+1;
            oldBest=Best.Cost; Best=UpdateBest(Best,trial(i,:),values(i));
            if Best.Cost<oldBest && isnan(info.FirstImprovementEvaluation)
                info.FirstImprovementEvaluation=info.Evaluations;
            end
            T(info.Evaluations)=Best.Cost;
        end
    end
    improved=values<fitness;
    goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved);
    archive=unique([archive;pop(improved,:)],'rows');
    if size(archive,1)>archiveCapacity
        archive=archive(randperm(size(archive,1),archiveCapacity),:);
    end
    accepted=false(sizepop,1); accepted(1:count)=values(1:count)<fitness(1:count);
    pop(accepted,:)=trial(accepted,:); fitness(accepted)=values(accepted);

    if ~isempty(goodF)
        weights=gain/sum(gain);
        memoryF(memoryPos)=sum(weights.*goodF.^2)/sum(weights.*goodF);
        if max(goodCR)==0 || memoryCR(memoryPos)==-1
            memoryCR(memoryPos)=-1;
        else
            memoryCR(memoryPos)=sum(weights.*goodCR.^2)/sum(weights.*goodCR);
        end
        memoryPos=mod(memoryPos,memorySize)+1;
    end

    if ~isOff
        trigger=false;
        if isPeriodic && info.Evaluations>=nextPeriodic
            trigger=true; nextPeriodic=nextPeriodic+periodicEvery;
        elseif isPlateau && (info.Evaluations-winStartFE)>=progressWindow
            rel=(winBest-Best.Cost)/max(abs(winBest),1);
            trigger=rel<plateauTol;
            winStartFE=info.Evaluations; winBest=Best.Cost;
        end
        if trigger
            nMigTrig=nMigTrig+1;
            [pop,fitness,nm,nb]=migrateWorst(pop,fitness,migFrac,isNiche,nicheX,nicheF,histX,histF,nMigTrig);
            nMigRounds=nMigRounds+double(nm>0); nMigrants=nMigrants+nm; nMigBetter=nMigBetter+nb;
            migTrace(end+1,:)=[info.Evaluations,nm,nb]; %#ok<AGROW>
            winStartFE=info.Evaluations; winBest=Best.Cost;
        end
    end

    plannedSize=max(minSize,round(initialSize+(minSize-initialSize)*info.Evaluations/budget));
    if sizepop>plannedSize
        [~,order]=sort(fitness);
        pop=pop(order(1:plannedSize),:); fitness=fitness(order(1:plannedSize));
        sizepop=plannedSize; archiveCapacity=round(archiveRate*sizepop);
        if size(archive,1)>archiveCapacity
            archive=archive(randperm(size(archive,1),archiveCapacity),:);
        end
    end
    info.PopulationHistory(end+1)=sizepop;
    info.ArchiveSizeHistory(end+1)=size(archive,1);
end

info.Algorithm='NMLSHADE'; info.Rounds=max(0,numel(info.PopulationHistory)-1);
info.Seed=seed; info.MemoryF=memoryF; info.MemoryCR=memoryCR;
info.FinalPopulationSize=sizepop; info.FinalPopulation=pop; info.FinalFitness=fitness;
info.FinalArchive=archive; info.FinalNicheBank=nicheX; info.FinalNicheFitness=nicheF;
info.MigMode=migMode; info.MigOn=double(~isOff); info.MigPeriodic=double(isPeriodic);
info.MigBankSize=size(nicheX,1); info.MigBankMax=bankCap; info.MigHistSize=size(histX,1);
info.MigProgressWindow=progressWindow; info.MigPlateauTol=plateauTol;
info.MigPeriodicEvery=periodicEvery; info.MigFrac=migFrac;
info.MigTriggers=nMigTrig; info.MigRounds=nMigRounds; info.MigMigrants=nMigrants;
info.MigBetter=nMigBetter; info.MigTrace=migTrace; info.Seconds=toc(clockStart);
end

function [pop,fitness,nm,nb]=migrateWorst(pop,fitness,frac,useNiche,Xv,Fv,Hx,Hf,k)
n=size(pop,1); m=max(1,min(n-1,round(frac*n)));
[~,ord]=sort(fitness); target=ord(end-m+1:end); worst=max(fitness(target));
nm=0; nb=0;
if useNiche
    poolX=Xv; poolF=Fv;
else
    poolX=Hx; poolF=Hf;
end
if isempty(poolX), return; end
valid=find(poolF<worst);
if isempty(valid), return; end
if useNiche
    [~,oo]=sort(poolF(valid)); pick=valid(oo(1:min(m,numel(oo))));
else
    step=max(1,floor(numel(valid)/max(m,1)));
    pick=zeros(1,0);
    for q=1:min(m,numel(valid))
        jj=mod((k-1)*step+q-1,numel(valid))+1; pick(end+1)=valid(jj); %#ok<AGROW>
    end
end
nm=numel(pick);
for q=1:nm
    i=target(q); old=fitness(i); pop(i,:)=poolX(pick(q),:); fitness(i)=poolF(pick(q));
    nb=nb+double(fitness(i)<old);
end
end

function [X,Fv]=bankAdmit(X,Fv,x,v,cap,sep,span)
if isempty(X)
    X=x; Fv=v; return;
end
d=sqrt(sum((X-repmat(x,size(X,1),1)).^2,2))/span;
[dmin,ni]=min(d);
if dmin>=sep
    if size(X,1)<cap
        X(end+1,:)=x; Fv(end+1,1)=v;
    else
        [worst,wi]=max(Fv);
        if v<worst, X(wi,:)=x; Fv(wi)=v; end
    end
elseif v<Fv(ni)
    X(ni,:)=x; Fv(ni)=v;
end
end

function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop;
r1=floor(rand(1,sizepop)*sizepop)+1; bad=r1==r0;
while any(bad), r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0; end
r2=floor(rand(1,sizepop)*poolSize)+1; bad=r2==r0 | r2==r1;
while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0 | r2==r1; end
end

function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost, Best.Vector=vector; Best.Cost=cost; end
end
