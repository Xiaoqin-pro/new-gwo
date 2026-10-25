function [Best,T,info]=LSHADE_CNEPSIN_CEC(f,state,~,N,seed)
%LSHADE_CNEPSIN_CEC  Full-frequency APF L-SHADE-cnEpSin style search core.
%   This implementation preserves strict evaluation accounting.  Candidate
%   ranking is updated only after a real function evaluation.  The archive
%   stores evaluated successful parents together with their fitness values.

clockStart=tic;
pop=state.initialPopulation;
D=size(pop,2);
sizepop=min(round(N),size(pop,1));
assert(sizepop>=4 && D>=1);
pop=pop(1:sizepop,:);
initialSize=sizepop;
minSize=4;
lb=state.lowerBound;
ub=state.upperBound;
budget=state.maxEvaluations;
assert(budget>=sizepop);
rng(seed,'twister');

pBestRate=0.11;
archiveRate=1.4;
memorySize=5;
pb=cfgValue(state,'cnePb',0.40);
ps=cfgValue(state,'cnePs',0.50);
LP=max(2,round(cfgValue(state,'cneLP',20)));
freqInit=cfgValue(state,'cneFreqInit',0.50);
nita0=[cfgValue(state,'cneNita1',10),cfgValue(state,'cneNita2',10)];
minPApf=[cfgValue(state,'cneMinPApf1',0),cfgValue(state,'cneMinPApf2',0)];
sinOn=cfgFlag(state,'cneSin',true);
apfOn=cfgFlag(state,'cneApf',true);
eigenOn=cfgFlag(state,'cneEigen',true);
forceCap=cfgValue(state,'cneForceCap',inf);

T=nan(budget,1);
fitness=zeros(sizepop,1);
Best.Cost=inf;
used=0;
for i=1:sizepop
    fitness(i)=f(pop(i,:));
    used=used+1;
    Best=UpdateBest(Best,pop(i,:),fitness(i));
    T(used)=Best.Cost;
end

memoryF=0.5*ones(memorySize,1);
memoryCR=0.5*ones(memorySize,1);
memoryFreq=freqInit*ones(memorySize,1);
memoryPos=1;
archive=zeros(0,D);
archiveF=zeros(0,1);
archiveCap=round(archiveRate*sizepop);

good1all=zeros(1,0); bad1all=zeros(1,0);
good2all=zeros(1,0); bad2all=zeros(1,0);
memoryNita1=zeros(0,1); memoryNita2=zeros(0,1);
pApf=[1,1];
rounds=0;
gMax=EstimateGenerations(budget,initialSize,minSize);
sinMode1Gens=0; sinMode2Gens=0;
apfApplied1=0; apfApplied2=0; apfGood1=0; apfGood2=0;

while used<budget
    rounds=rounds+1;
    [~,order]=sort(fitness);
    memoryIndex=ceil(memorySize*rand(sizepop,1));
    muF=memoryF(memoryIndex);
    muCR=memoryCR(memoryIndex);
    muFreq=memoryFreq(memoryIndex);

    CR=muCR+0.1*randn(sizepop,1);
    CR(muCR==-1)=0;
    CR=max(0,min(1,CR));

    F0=muF+0.1*tan(pi*(rand(sizepop,1)-0.5));
    bad=find(F0<=0);
    while ~isempty(bad)
        F0(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5));
        bad=find(F0<=0);
    end
    F0=min(1,F0);

    freq=muFreq+0.1*tan(pi*(rand(sizepop,1)-0.5));
    bad=find(freq<=0);
    while ~isempty(bad)
        freq(bad)=muFreq(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5));
        bad=find(freq<=0);
    end
    freq=min(1,freq);

    F=F0;
    modeUsed=0;
    if sinOn && used<=budget/2
        if rounds<=LP
            if rand<0.5, modeUsed=1; else, modeUsed=2; end
        else
            p1=ModeProbability(good1all,bad1all,rounds,LP);
            p2=ModeProbability(good2all,bad2all,rounds,LP);
            if p1>p2, modeUsed=1; else, modeUsed=2; end
        end
        if modeUsed==1
            osc=0.5*(sin(2*pi*freqInit*rounds+pi)*((gMax-rounds)/max(gMax,1))+1);
            osc=osc*ones(sizepop,1);
            sinMode1Gens=sinMode1Gens+1;
        else
            osc=0.5*(sin(2*pi*freq*rounds).*(rounds/max(gMax,1))+1);
            sinMode2Gens=sinMode2Gens+1;
        end
        F=(F0+osc)/2;
    end

    pool=[pop;archive];
    poolF=[fitness;archiveF];
    [r1,r2]=RandomParents(sizepop,size(pool,1));
    pCount=max(round(pBestRate*sizepop),2);
    pIndex=max(1,ceil(rand(1,sizepop)*pCount));
    pbest=pop(order(pIndex),:);
    pbestF=fitness(order(pIndex));

    % Element (i,j) is the distance from parent i to target j.
    D1=DistanceMatrix(pop,pbest);
    D2=DistanceMatrix(pop,pool);
    newNita1=zeros(0,2);
    newNita2=zeros(0,2);
    indexNita1=GetMemoryIndex(memoryNita1,sizepop);
    indexNita2=GetMemoryIndex(memoryNita2,sizepop);
    mutant=zeros(sizepop,D);
    if apfOn
        for i=1:sizepop
            [Frep1,record1]=ApfForce(pop(i,:),fitness(i),pbestF(:)',pbest,D1(i,:),i,pApf(1), ...
                nita0(1),memoryNita1,indexNita1(i),forceCap,sizepop);
            if ~isempty(record1), newNita1(end+1,:)=record1; end
            [Frep2,record2]=ApfForce(pop(i,:),fitness(i),poolF(:)',pool,D2(i,:),r2(i),pApf(2), ...
                nita0(2),memoryNita2,indexNita2(i),forceCap,sizepop);
            if ~isempty(record2), record2(2)=i; newNita2(end+1,:)=record2; end
            mutant(i,:)=pop(i,:)+F(i)*(pbest(i,:)-pop(i,:)+Frep1+pop(r1(i),:)-pool(r2(i),:)+Frep2);
        end
    else
        mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
    end
    mutant=BoundConstraint(mutant,pop,lb,ub);

    jr=floor(rand(sizepop,1)*D)+1;
    crs=rand(sizepop,D)<=CR;
    jlin=sub2ind([sizepop D],(1:sizepop)',jr);
    crs(jlin)=true;

    if eigenOn && rand<pb
        best=pop(order(1),:);
        dist=sqrt(sum((pop-repmat(best,sizepop,1)).^2,2));
        [~,near]=sort(dist);
        sel=max(4,round(ps*sizepop));
        Xsel=pop(near(1:min(sel,sizepop)),:);
        if size(Xsel,1)<=1
            R=eye(D);
        else
            xm=mean(Xsel,1);
            Xc=Xsel-repmat(xm,size(Xsel,1),1);
            Cc=(Xc'*Xc)/(size(Xsel,1)-1);
            Cc=(Cc+Cc')/2;
            if any(~isfinite(Cc(:)))
                R=eye(D);
            else
                d0=eig(Cc);
                if any(~isfinite(d0(:)))
                    R=eye(D);
                else
                    if max(d0) > 1e20*min(d0)
                        Cc = Cc + (max(d0)/1e20 - min(d0))*eye(D);
                        d0 = eig(Cc);
                    end
                    [R,L]=eig(Cc);
                    if any(~isfinite(L(:))), R=eye(D); end
                end
            end
        end
        Xr=pop*R;
        Vr=mutant*R;
        Ur=Xr;
        Ur(crs)=Vr(crs);
        trial=Ur*R';
    else
        trial=pop;
        trial(crs)=mutant(crs);
    end
    trial=BoundConstraint(trial,pop,lb,ub);

    count=min(sizepop,budget-used);
    values=fitness;
    oldFitness=fitness;
    for i=1:count
        values(i)=f(trial(i,:));
        used=used+1;
        Best=UpdateBest(Best,trial(i,:),values(i));
        T(used)=Best.Cost;
    end
    improved=false(sizepop,1);
    improved(1:count)=values(1:count)<oldFitness(1:count);

    [memoryNita1,pApf(1),ng1]=UpdateApf(memoryNita1,pApf(1),newNita1,improved,sizepop,minPApf(1));
    [memoryNita2,pApf(2),ng2]=UpdateApf(memoryNita2,pApf(2),newNita2,improved,sizepop,minPApf(2));
    apfApplied1=apfApplied1+size(newNita1,1);
    apfApplied2=apfApplied2+size(newNita2,1);
    apfGood1=apfGood1+ng1;
    apfGood2=apfGood2+ng2;

    if improved(1:count)
        [archive,archiveF]=UpdateArchive(archive,archiveF,pop(improved,:),oldFitness(improved),archiveCap);
    end

    goodF=F(improved);
    goodCR=CR(improved);
    goodFreq=freq(improved);
    gain=oldFitness(improved)-values(improved);
    if ~isempty(goodF) && any(gain>0)
        w=gain/sum(gain);
        memoryF(memoryPos)=sum(w.*goodF.^2)/max(sum(w.*goodF),realmin);
        if max(goodCR)==0 || memoryCR(memoryPos)==-1
            memoryCR(memoryPos)=-1;
        else
            memoryCR(memoryPos)=sum(w.*goodCR.^2)/max(sum(w.*goodCR),realmin);
        end
        if max(goodFreq)==0 || memoryFreq(memoryPos)==-1
            memoryFreq(memoryPos)=-1;
        else
            memoryFreq(memoryPos)=sum(w.*goodFreq.^2)/max(sum(w.*goodFreq),realmin);
        end
        memoryPos=mod(memoryPos,memorySize)+1;
    end

    pop(improved,:)=trial(improved,:);
    fitness(improved)=values(improved);

    % Record both modes every generation for the SaDE-style mode probability.
    g1=0; b1=0; g2=0; b2=0;
    if modeUsed==1
        g1=sum(improved(1:count)); b1=count-g1;
    elseif modeUsed==2
        g2=sum(improved(1:count)); b2=count-g2;
    end
    if rounds>numel(good1all)
        good1all(rounds)=1; bad1all(rounds)=1;
        good2all(rounds)=1; bad2all(rounds)=1;
    end
    if modeUsed==1
        good1all(rounds)=g1; bad1all(rounds)=b1;
    elseif modeUsed==2
        good2all(rounds)=g2; bad2all(rounds)=b2;
    end

    planned=max(minSize,round(initialSize+(minSize-initialSize)*used/budget));
    if sizepop>planned
        [~,order]=sort(fitness);
        pop=pop(order(1:planned),:);
        fitness=fitness(order(1:planned));
        sizepop=planned;
        archiveCap=round(archiveRate*sizepop);
        if size(archive,1)>archiveCap
            keep=randperm(size(archive,1),archiveCap);
            archive=archive(keep,:); archiveF=archiveF(keep);
        end
    end
end

info.Algorithm='LSHADE-CNEPSIN-FULL';
info.Evaluations=used;
info.Rounds=rounds;
info.FinalPopulation=pop;
info.FinalFitness=fitness;
info.FinalArchive=archive;
info.FinalArchiveFitness=archiveF;
info.FinalPopulationSize=sizepop;
info.MemoryF=memoryF;
info.MemoryCR=memoryCR;
info.MemoryFreq=memoryFreq;
info.PApf=pApf;
info.GMax=gMax;
info.CneSin=sinOn;
info.CneApf=apfOn;
info.CneEigen=eigenOn;
info.SinMode1Gens=sinMode1Gens;
info.SinMode2Gens=sinMode2Gens;
info.ApfApplied1=apfApplied1;
info.ApfApplied2=apfApplied2;
info.ApfGood1=apfGood1;
info.ApfGood2=apfGood2;
info.Seconds=toc(clockStart);
assert(used==budget && numel(T)==budget && abs(T(end)-Best.Cost)<1e-12, ...
    'LSHADE_CNEPSIN_CEC evaluation contract violated.');
end

function value=cfgValue(state,name,defaultValue)
if isfield(state,name) && ~isempty(state.(name)), value=state.(name); else, value=defaultValue; end
end
function value=cfgFlag(state,name,defaultValue)
if isfield(state,name) && ~isempty(state.(name)), value=logical(state.(name)); else, value=defaultValue; end
end
function p=ModeProbability(good,bad,generation,LP)
lo=max(1,generation-LP);
g=sum(good(lo:generation-1));
b=sum(bad(lo:generation-1));
p=g/(g+b)+0.01;
end
function gMax=EstimateGenerations(budget,initialSize,minSize)
gMax=0; nfes=initialSize; p=initialSize;
while nfes<budget
    gMax=gMax+1;
    nfes=min(budget,nfes+p);
    p=max(minSize,round(initialSize+(minSize-initialSize)*nfes/budget));
end
gMax=max(gMax,1);
end
function index=GetMemoryIndex(memory,popSize)
if isempty(memory), index=zeros(popSize,1); else, index=randi(numel(memory),popSize,1); end
end
function D=DistanceMatrix(A,B)
D=zeros(size(A,1),size(B,1));
for i=1:size(A,1)
    diff=B-repmat(A(i,:),size(B,1),1);
    D(i,:)=sqrt(sum(diff.^2,2))';
end
end
function [Frep,record]=ApfForce(currentPos,currentF,targetF,targets,distRow,targetIndex,pApf,nita0,memory,memIndex,forceCap,popSize)
Frep=zeros(1,numel(currentPos)); record=zeros(0,2);
if targetF(targetIndex)>=currentF || rand>=pApf, return; end
centreDist=distRow(targetIndex);
if ~isfinite(centreDist) || centreDist<=0, return; end
if ~isempty(memory) && numel(memory)>popSize
    nita=0.8*memory(memIndex)+0.2*(nita0+randn*nita0);
else
    nita=nita0+randn*nita0;
end
record=[nita,targetIndex];
radius=centreDist/2;
near=find(distRow<radius & targetF<currentF);
if isempty(near), return; end
for j=near
    d=distRow(j);
    if d<=realmin || ~isfinite(d), continue; end
    term=0.5*nita*radius*(1/d-1/radius)/(d^2);
    Frep=Frep+term*(targets(j,:)-currentPos);
end
if forceCap>0 && isfinite(forceCap)
    cap=forceCap*max(1,norm(targets(targetIndex,:)-currentPos));
    nf=norm(Frep);
    if nf>cap, Frep=Frep*(cap/nf); end
end
if any(~isfinite(Frep)), Frep=zeros(1,numel(currentPos)); end
end
function [memory,pApf,numGood]=UpdateApf(memory,pApf,newNita,improved,popSize,minPApf)
numGood=0;
if isempty(newNita), return; end
idx=newNita(:,2);
valid=idx>=1 & idx<=numel(improved);
good=newNita(valid & improved(idx),1);
numGood=numel(good);
memory=[memory;good];
cap=max(2*popSize,2);
if numel(memory)>cap, memory=memory(end-cap+1:end); end
successRate=numGood/size(newNita,1);
pApf=max(minPApf,0.8*pApf+0.2*successRate);
end
function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop;
r1=floor(rand(1,sizepop)*sizepop)+1;
bad=r1==r0;
while any(bad)
    r1(bad)=floor(rand(1,sum(bad))*sizepop)+1;
    bad=r1==r0;
end
r2=floor(rand(1,sizepop)*poolSize)+1;
bad=r2==r0 | r2==r1;
while any(bad)
    r2(bad)=floor(rand(1,sum(bad))*poolSize)+1;
    bad=r2==r0 | r2==r1;
end
end
function X=BoundConstraint(X,pop,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); P=pop(1:size(X,1),:);
out=X<lo; X(out)=(P(out)+lo(out))/2;
out=X>hi; X(out)=(P(out)+hi(out))/2;
end
function [archive,archiveF]=UpdateArchive(archive,archiveF,newPop,newF,cap)
if isempty(newPop) || cap<=0, return; end
popAll=[archive;newPop];
funAll=[archiveF;newF];
[popAll,ia]=unique(popAll,'rows','stable');
funAll=funAll(ia);
if size(popAll,1)>cap
    keep=randperm(size(popAll,1),cap);
    popAll=popAll(keep,:); funAll=funAll(keep);
end
archive=popAll; archiveF=funAll;
end
function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost, Best.Vector=vector; Best.Cost=cost; end
end





