function [Best,T,info] = LSHADE_RESUME(f,state,~,N,seed)
%LSHADE_RESUME  L-SHADE continuation from a verified GWO population/archive.
pop=state.initialPopulation; fitness=state.initialFitness(:);
[sizepop,D]=size(pop); assert(sizepop==N && numel(fitness)==N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=0);
rng(seed,'twister');
Best=struct('Cost',inf,'Vector',zeros(1,D));
if isfield(state,'initialBest') && isfield(state.initialBest,'Cost')
    Best=state.initialBest;
else
    [Best.Cost,ii]=min(fitness); Best.Vector=pop(ii,:);
end
T=nan(budget,1); if budget>0, T(1)=Best.Cost; end
info.Evaluations=0; info.Algorithm='LSHADE-RESUME'; info.Rounds=0;
info.PopulationHistory=sizepop; info.ArchiveSizeHistory=0; info.InitialCost=Best.Cost;
memoryF=0.5*ones(5,1); memoryCR=0.5*ones(5,1); memoryPos=1;
archive=zeros(0,D);
if isfield(state,'initialArchive') && ~isempty(state.initialArchive), archive=state.initialArchive; end
archiveCapacity=round(1.4*sizepop);
if size(archive,1)>archiveCapacity, archive=archive(randperm(size(archive,1),archiveCapacity),:); end
while info.Evaluations<budget
    info.Rounds=info.Rounds+1;
    [~,order]=sort(fitness);
    memoryIndex=ceil(5*rand(sizepop,1)); muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
    CR=muCR+0.1*randn(sizepop,1); CR(max(muCR,0)==0)=0; CR=max(0,min(1,CR));
    F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5)); bad=find(F<=0);
    while ~isempty(bad), F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5)); bad=find(F<=0); end
    F=min(1,F); pool=[pop;archive];
    [r1,r2]=randomParents(sizepop,size(pool,1));
    pCount=max(round(0.11*sizepop),2); pIndex=max(1,ceil(rand(1,sizepop)*pCount)); pbest=pop(order(pIndex),:);
    mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
    lower=repmat(lb,sizepop,1); upper=repmat(ub,sizepop,1);
    outside=mutant<lower; mutant(outside)=(pop(outside)+lower(outside))/2;
    outside=mutant>upper; mutant(outside)=(pop(outside)+upper(outside))/2;
    mask=rand(sizepop,D)>CR; jrand=sub2ind([sizepop D],(1:sizepop)',floor(rand(sizepop,1)*D)+1); mask(jrand)=false;
    trial=mutant; trial(mask)=pop(mask);
    count=min(sizepop,budget-info.Evaluations); values=fitness;
    for i=1:count
        values(i)=f(trial(i,:)); info.Evaluations=info.Evaluations+1;
        if values(i)<Best.Cost, Best.Vector=trial(i,:); Best.Cost=values(i); end
        T(info.Evaluations)=Best.Cost;
    end
    improved=values<fitness; goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved);
    if any(improved), archive=unique([archive;pop(improved,:)],'rows'); end
    if size(archive,1)>archiveCapacity, archive=archive(randperm(size(archive,1),archiveCapacity),:); end
    accepted=false(sizepop,1); accepted(1:count)=values(1:count)<fitness(1:count);
    pop(accepted,:)=trial(accepted,:); fitness(accepted)=values(accepted);
    if ~isempty(goodF)
        weights=gain/sum(gain); memoryF(memoryPos)=sum(weights.*goodF.^2)/sum(weights.*goodF);
        if max(goodCR)==0 || memoryCR(memoryPos)==-1, memoryCR(memoryPos)=-1; else, memoryCR(memoryPos)=sum(weights.*goodCR.^2)/sum(weights.*goodCR); end
        memoryPos=mod(memoryPos,5)+1;
    end
    planned=max(4,round(sizepop+(4-sizepop)*info.Evaluations/budget));
    if sizepop>planned
        [~,order]=sort(fitness); pop=pop(order(1:planned),:); fitness=fitness(order(1:planned)); sizepop=planned; archiveCapacity=round(1.4*sizepop);
        if size(archive,1)>archiveCapacity, archive=archive(randperm(size(archive,1),archiveCapacity),:); end
    end
    info.PopulationHistory(end+1)=sizepop; info.ArchiveSizeHistory(end+1)=size(archive,1);
end
info.FinalPopulation=pop; info.FinalFitness=fitness; info.FinalArchive=archive; info.FinalPopulationSize=sizepop;
end
function [r1,r2]=randomParents(sizepop,poolSize)
r0=1:sizepop; r1=floor(rand(1,sizepop)*sizepop)+1; bad=r1==r0;
while any(bad), r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0; end
r2=floor(rand(1,sizepop)*poolSize)+1; bad=r2==r0 | r2==r1;
while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0 | r2==r1; end
end
