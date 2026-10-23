function [Best,T,info]=ASLSHADE(f,state,~,N,seed)
%ASLSHADE  Credit-scheduled evaluation sparsity for L-SHADE.
%   The trial generator and all L-SHADE adaptation remain unchanged.  A
%   window scheduler chooses how many trials are evaluated: K=10, 25 or 50.
%   Rewards are normalized real global-best progress over equal-FE windows.
%   The random-K arm uses the same K grid and the same dual-potential screen.
%
%   state.screenMode:
%     'dense'     : evaluate all trials (LSHADE_CEC baseline)
%     'fixedK'    : fixed K = state.sparseK
%     'randomK'   : uniformly random K from state.kChoices
%     'adaptiveK' : epsilon-greedy credit scheduler over the same K grid
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
screenMode='adaptiveK';
if isfield(state,'screenMode') && ~isempty(state.screenMode), screenMode=lower(char(state.screenMode)); end
isDense=strcmp(screenMode,'dense');
isFixed=strcmp(screenMode,'fixedk');
isRandomK=strcmp(screenMode,'randomk');
isAdaptiveK=strcmp(screenMode,'adaptivek'); isStagK=strcmp(screenMode,'stagnationk');
assert(isDense||isFixed||isRandomK||isAdaptiveK||isStagK,'unknown screenMode');
sparseK=10; nearFrac=0.50; kChoices=[10 25 50]; kWindowFrac=0.02; epsExplore=0.10;
if isfield(state,'sparseK') && ~isempty(state.sparseK), sparseK=state.sparseK; end
if isfield(state,'screenNearFrac') && ~isempty(state.screenNearFrac), nearFrac=state.screenNearFrac; end
if isfield(state,'kChoices') && ~isempty(state.kChoices), kChoices=state.kChoices; end
if isfield(state,'kWindowFrac') && ~isempty(state.kWindowFrac), kWindowFrac=state.kWindowFrac; end
if isfield(state,'epsExplore') && ~isempty(state.epsExplore), epsExplore=state.epsExplore; end
kChoices=sort(unique(round(kChoices(:)')));
kChoices=kChoices(kChoices>0); assert(~isempty(kChoices),'empty K grid');
nearFrac=min(1,max(0,nearFrac)); kWindow=max(2*N,round(kWindowFrac*budget)); span=max(norm(ub-lb),eps);

fitness=zeros(sizepop,1); T=nan(budget,1); Best.Cost=inf;
for i=1:sizepop
    fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost;
end
info.Evaluations=sizepop; info.InitialCost=Best.Cost;
info.InitialPopulation=pop; info.FirstImprovementEvaluation=NaN;
info.PopulationHistory=sizepop; info.ArchiveSizeHistory=0;
memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1); memoryPos=1;
archive=zeros(0,D); archiveCapacity=round(archiveRate*sizepop);
nTrials=0; nSelect=0; nNear=0; nFar=0; rounds=0;
kCount=zeros(1,numel(kChoices)); kReward=zeros(1,numel(kChoices)); kTrace=zeros(0,4); stagLevel=1;
if isDense
    KNow=sizepop; actionIdx=0;
elseif isFixed
    KNow=min(sparseK,sizepop); actionIdx=0;
elseif isStagK
    actionIdx=1; KNow=min(kChoices(1),sizepop);
    winStart=info.Evaluations; winBest=Best.Cost; winEnd=min(budget,winStart+kWindow);
    kTrace(end+1,:)=[info.Evaluations,KNow,actionIdx,0]; %#ok<AGROW>
else
    actionIdx=min(numel(kChoices),max(1,find(kChoices>=25,1)));
    KNow=min(kChoices(actionIdx),sizepop);
    winStart=info.Evaluations; winBest=Best.Cost; winEnd=min(budget,winStart+kWindow);
    kTrace(end+1,:)=[info.Evaluations,KNow,actionIdx,0]; %#ok<AGROW>
end

while info.Evaluations<budget
    rounds=rounds+1;
    if (isRandomK||isAdaptiveK||isStagK) && info.Evaluations>=winEnd
        rw=(winBest-Best.Cost)/max(abs(winBest),1);
        kCount(actionIdx)=kCount(actionIdx)+1; kReward(actionIdx)=kReward(actionIdx)+rw;
        if isStagK
            if rw<5e-4
                stagLevel=min(numel(kChoices),stagLevel+1);
            else
                stagLevel=max(1,stagLevel-1);
            end
            actionIdx=stagLevel;
        elseif isRandomK
            actionIdx=randi(numel(kChoices));
        elseif any(kCount==0)
            actionIdx=find(kCount==0,1);
        elseif rand<epsExplore
            actionIdx=randi(numel(kChoices));
        else
            mr=kReward./max(kCount,1); [~,actionIdx]=max(mr);
        end
        KNow=min(kChoices(actionIdx),sizepop);
        winStart=info.Evaluations; winBest=Best.Cost; winEnd=min(budget,winStart+kWindow);
        kTrace(end+1,:)=[info.Evaluations,KNow,actionIdx,rw]; %#ok<AGROW>
    end
    if ~isDense, KNow=min(KNow,sizepop); end
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
    nTrials=nTrials+sizepop;
    if isDense
        sel=(1:sizepop)'; nn=0; nf=0;
    else
        [sel,nn,nf]=screenTrials(trial,sizepop,min(KNow,sizepop),Best.Vector,span,nearFrac);
    end
    nSelect=nSelect+numel(sel); nNear=nNear+nn; nFar=nFar+nf;
    count=min(numel(sel),budget-info.Evaluations); sel=sel(1:count); values=fitness;
    for j=1:count
        i=sel(j); values(i)=f(trial(i,:)); info.Evaluations=info.Evaluations+1;
        oldBest=Best.Cost; Best=UpdateBest(Best,trial(i,:),values(i));
        if Best.Cost<oldBest && isnan(info.FirstImprovementEvaluation)
            info.FirstImprovementEvaluation=info.Evaluations;
        end
        T(info.Evaluations)=Best.Cost;
    end
    improved=values<fitness; goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved);
    parents=pop(improved,:); archive=unique([archive;parents],'rows');
    if size(archive,1)>archiveCapacity, archive=archive(randperm(size(archive,1),archiveCapacity),:); end
    accepted=false(sizepop,1); accepted(sel)=values(sel)<fitness(sel);
    pop(accepted,:)=trial(accepted,:); fitness(accepted)=values(accepted);
    if ~isempty(goodF)
        weights=gain/sum(gain);
        memoryF(memoryPos)=sum(weights.*goodF.^2)/sum(weights.*goodF);
        if max(goodCR)==0 || memoryCR(memoryPos)==-1, memoryCR(memoryPos)=-1; else
            memoryCR(memoryPos)=sum(weights.*goodCR.^2)/sum(weights.*goodCR);
        end
        memoryPos=mod(memoryPos,memorySize)+1;
    end
    plannedSize=max(minSize,round(initialSize+(minSize-initialSize)*info.Evaluations/budget));
    if sizepop>plannedSize
        [~,order]=sort(fitness); pop=pop(order(1:plannedSize),:); fitness=fitness(order(1:plannedSize));
        sizepop=plannedSize; archiveCapacity=round(archiveRate*sizepop);
        if size(archive,1)>archiveCapacity, archive=archive(randperm(size(archive,1),archiveCapacity),:); end
    end
    info.PopulationHistory(end+1)=sizepop; info.ArchiveSizeHistory(end+1)=size(archive,1);
end
info.Algorithm='ASLSHADE'; info.Rounds=rounds; info.Seed=seed;
info.MemoryF=memoryF; info.MemoryCR=memoryCR; info.FinalPopulationSize=sizepop;
info.FinalPopulation=pop; info.FinalFitness=fitness; info.FinalArchive=archive;
info.ScreenMode=screenMode; info.SparseK=sparseK; info.ScreenNearFrac=nearFrac;
info.KChoices=kChoices; info.KWindow=kWindow; info.KCounts=kCount; info.KRewards=kReward;
info.KMeanReward=kReward./max(kCount,1); info.KTrace=kTrace; info.KLevel=stagLevel;
info.TrialsGenerated=nTrials; info.TrialsSelected=nSelect; info.NearSelected=nNear; info.FarSelected=nFar;
info.Seconds=toc(clockStart);
end

function [sel,nn,nf]=screenTrials(trial,N,K,best,span,nearFrac)
d=sqrt(sum((trial-repmat(best,N,1)).^2,2))/span;
[~,ord]=sort(d,'ascend');
nn=max(1,min(K,round(nearFrac*K))); nf=K-nn; sel=ord(1:nn);
if nf>0
    rem=setdiff((1:N)',sel); selected=sel; [~,fi]=max(d(rem)); pick=rem(fi);
    selected(end+1)=pick; rem(rem==pick)=[];
    while numel(selected)<K && ~isempty(rem)
        dd=zeros(numel(rem),1);
        for q=1:numel(rem)
            dd(q)=min(sqrt(sum((trial(selected,:)-repmat(trial(rem(q),:),numel(selected),1)).^2,2)))/span;
        end
        [~,qi]=max(dd); pick=rem(qi); selected(end+1)=pick; rem(rem==pick)=[]; %#ok<AGROW>
    end
    sel=selected(1:K);
end
end

function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop; r1=floor(rand(1,sizepop)*sizepop)+1; bad=r1==r0;
while any(bad), r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0; end
r2=floor(rand(1,sizepop)*poolSize)+1; bad=r2==r0 | r2==r1;
while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0 | r2==r1; end
end

function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost, Best.Vector=vector; Best.Cost=cost; end
end
