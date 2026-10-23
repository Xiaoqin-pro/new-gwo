function [Best,T,info]=NELSHADE(f,state,~,N,seed)
%NELSHADE  Niche-ecological L-SHADE with verified niche memory.
%   The base L-SHADE reproduction channel (current-to-pbest/1) is retained.
%   A second channel uses a spatially separated, verified niche bank.  The
%   two channels have independent F/CR success memories.  In the adaptive
%   mode their share is scheduled by real global-best stagnation and by
%   channel-specific realised success.  No unverified point enters the bank.
%
%   state.ecoMode:
%     'off'             : bitwise-equivalent to LSHADE_CEC
%     'random_adaptive' : matched control; leader from top-half current pop
%     'niche_fixed'     : niche bank + fixed niche share
%     'niche_adaptive'  : niche bank + adaptive ecological share
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

ecoMode='niche_adaptive';
if isfield(state,'ecoMode') && ~isempty(state.ecoMode), ecoMode=lower(char(state.ecoMode)); end
isOff=strcmp(ecoMode,'off');
isNiche=~isOff && ~strcmp(ecoMode,'random_adaptive');
isAdaptive=~isOff && ~strcmp(ecoMode,'niche_fixed');
ecoBaseProb=0.20; ecoMinProb=0.10; ecoMaxProb=0.60;
ecoStagnProb=0.65; ecoStagnFrac=0.08; ecoNicheCap=24; ecoSepFrac=0.02; ecoLeaderK=5;
ecoRescueFrac=0.50; ecoStallMin=2;
if isfield(state,'ecoBaseProb') && ~isempty(state.ecoBaseProb), ecoBaseProb=state.ecoBaseProb; end
if isfield(state,'ecoMinProb') && ~isempty(state.ecoMinProb), ecoMinProb=state.ecoMinProb; end
if isfield(state,'ecoMaxProb') && ~isempty(state.ecoMaxProb), ecoMaxProb=state.ecoMaxProb; end
if isfield(state,'ecoStagnProb') && ~isempty(state.ecoStagnProb), ecoStagnProb=state.ecoStagnProb; end
if isfield(state,'ecoStagnFrac') && ~isempty(state.ecoStagnFrac), ecoStagnFrac=state.ecoStagnFrac; end
if isfield(state,'ecoNicheCap') && ~isempty(state.ecoNicheCap), ecoNicheCap=state.ecoNicheCap; end
if isfield(state,'ecoSepFrac') && ~isempty(state.ecoSepFrac), ecoSepFrac=state.ecoSepFrac; end
if isfield(state,'ecoLeaderK') && ~isempty(state.ecoLeaderK), ecoLeaderK=state.ecoLeaderK; end
if isfield(state,'ecoRescueFrac') && ~isempty(state.ecoRescueFrac), ecoRescueFrac=state.ecoRescueFrac; end
if isfield(state,'ecoStallMin') && ~isempty(state.ecoStallMin), ecoStallMin=state.ecoStallMin; end
ecoNicheCap=max(4,round(ecoNicheCap)); ecoTau=max(1,round(ecoStagnFrac*budget));
span=max(norm(ub-lb),eps);

fitness=zeros(sizepop,1);
T=nan(budget,1);
Best.Cost=inf;
for i=1:sizepop
    fitness(i)=f(pop(i,:));
    Best=UpdateBest(Best,pop(i,:),fitness(i));
    T(i)=Best.Cost;
end
info.Evaluations=sizepop; info.InitialCost=Best.Cost;
info.InitialPopulation=pop; info.FirstImprovementEvaluation=NaN;
info.PopulationHistory=sizepop; info.ArchiveSizeHistory=0;

memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1);
memoryF2=0.5*ones(memorySize,1); memoryCR2=0.5*ones(memorySize,1);
memoryPos=1; memoryPos2=1;
archive=zeros(0,D); archiveCapacity=round(archiveRate*sizepop);
bankX=zeros(0,D); bankF=zeros(0,1); bankAge=zeros(0,1);
nBankAdmit=0; nBankReplace=0; bankEvalCount=0; stallCount=zeros(sizepop,1);
lastGB=sizepop; pNiche=ecoBaseProb; pAdapt=ecoBaseProb;
emaN=ecoBaseProb; emaB=ecoBaseProb;
pTrace=zeros(0,1); nicheSrcGen=0; nicheEvalCount=0; nicheSuccCount=0;
baseEvalCount=0; baseSuccCount=0; ecoGens=0; stagGens=0;
if isNiche
    [~,ord0]=sort(fitness);
    nSeed=min(N,max(4,round(0.5*N)));
    for ii=1:nSeed
        [bankX,bankF,bankAge,a,r]=bankAdmit(bankX,bankF,bankAge,pop(ord0(ii),:), ...
            fitness(ord0(ii)),ecoNicheCap,ecoSepFrac,span);
        nBankAdmit=nBankAdmit+double(a); nBankReplace=nBankReplace+double(r);
    end
end

while info.Evaluations<budget
    ecoGens=ecoGens+1;
    [~,order]=sort(fitness);
    if isOff
        memoryIndex=ceil(memorySize*rand(sizepop,1));
        muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
        src=ones(sizepop,1); pNow=0;
    else
        stag=info.Evaluations-lastGB;
        if isAdaptive
            frac=min(1,stag/ecoTau);
            pStag=ecoBaseProb+(ecoStagnProb-ecoBaseProb)*frac;
            pNow=0.5*(pAdapt+pStag);
            pNow=min(ecoMaxProb,max(ecoMinProb,pNow));
            if frac>=1, stagGens=stagGens+1; end
        else
            pNow=ecoBaseProb;
        end
        nN=max(0,min(sizepop,round(pNow*sizepop)));
        src=ones(sizepop,1);
        if nN>0
            nTail=max(1,round(min(1,max(0,ecoRescueFrac))*sizepop));
            tail=order(max(1,sizepop-nTail+1):sizepop);
            eligible=unique([tail; find(stallCount>=ecoStallMin)]);
            if isempty(eligible), eligible=order(end); end
            pp=randperm(numel(eligible));
            pick=eligible(pp(1:min(nN,numel(eligible))));
            src(pick)=2;
        end
        memoryIndex=ceil(memorySize*rand(sizepop,1));
        muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
        idx2=find(src==2);
        if ~isempty(idx2)
            muF(idx2)=memoryF2(memoryIndex(idx2)); muCR(idx2)=memoryCR2(memoryIndex(idx2));
        end
    end
    pTrace(end+1,1)=pNow; %#ok<AGROW>
    if ~isOff, pNiche=pNow; end
    CR=muCR+0.1*randn(sizepop,1); CR(muCR==-1)=0; CR=max(0,min(1,CR));
    F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5));
    bad=find(F<=0);
    while ~isempty(bad)
        F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5));
        bad=find(F<=0);
    end
    F=min(1,F);

    pool=[pop;archive];
    [r1,r2]=RandomParents(sizepop,size(pool,1));
    pCount=max(round(pBestRate*sizepop),2);
    pIndex=max(1,ceil(rand(1,sizepop)*pCount));
    pbest=pop(order(pIndex),:);
    mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
    if ~isOff
        lead=zeros(sizepop,D);
        idx2=find(src==2);
        for jj=1:numel(idx2)
            i=idx2(jj);
            if isNiche && ~isempty(bankX)
                m=size(bankX,1);
                dd=sqrt(sum((bankX-repmat(pop(i,:),m,1)).^2,2));
                [~,near]=sort(dd);
                kk=min(max(1,round(ecoLeaderK)),m);
                cand=near(1:kk);
                [~,mi]=min(bankF(cand)); lead(i,:)=bankX(cand(mi),:);
            else
                topN=max(2,ceil(0.5*sizepop));
                cand=order(1:topN);
                kk=min(max(1,round(ecoLeaderK)),numel(cand));
                if numel(cand)>kk, cand=cand(randperm(numel(cand),kk)); end
                [~,mi]=min(fitness(cand)); lead(i,:)=pop(cand(mi),:);
            end
        end
        if ~isempty(idx2)
            mutant(idx2,:)=pop(idx2,:)+F(idx2).*(lead(idx2,:)-pop(idx2,:) ...
                +pop(r1(idx2),:)-pool(r2(idx2),:));
        end
    end
    lowB=repmat(lb,sizepop,1); upB=repmat(ub,sizepop,1);
    outside=mutant<lowB; mutant(outside)=(pop(outside)+lowB(outside))/2;
    outside=mutant>upB; mutant(outside)=(pop(outside)+upB(outside))/2;
    mask=rand(sizepop,D)>CR;
    jrand=sub2ind([sizepop D],(1:sizepop)',floor(rand(sizepop,1)*D)+1);
    mask(jrand)=false;
    trial=mutant; trial(mask)=pop(mask);

    count=min(sizepop,budget-info.Evaluations);
    values=fitness; medFit=median(fitness(1:sizepop)); genBestBefore=Best.Cost;
    for i=1:count
        values(i)=f(trial(i,:));
        info.Evaluations=info.Evaluations+1;
        Best=UpdateBest(Best,trial(i,:),values(i));
        if Best.Cost<genBestBefore && isnan(info.FirstImprovementEvaluation)
            info.FirstImprovementEvaluation=info.Evaluations;
        end
        T(info.Evaluations)=Best.Cost;
    end
    improved=values<fitness;
    accepted=false(sizepop,1); accepted(1:count)=values(1:count)<fitness(1:count);
    if ~isOff
        nicheSrcGen=nicheSrcGen+sum(src==2);
        nicheEvalCount=nicheEvalCount+sum(src(1:count)==2);
        baseEvalCount=baseEvalCount+sum(src(1:count)==1);
        nicheSuccCount=nicheSuccCount+sum(improved(1:count)&src(1:count)==2);
        baseSuccCount=baseSuccCount+sum(improved(1:count)&src(1:count)==1);
        if isNiche
            for i=1:count
                if isfinite(values(i)) && values(i)<=medFit
                    [bankX,bankF,bankAge,a,r]=bankAdmit(bankX,bankF,bankAge,trial(i,:), ...
                        values(i),ecoNicheCap,ecoSepFrac,span);
                    nBankAdmit=nBankAdmit+double(a); nBankReplace=nBankReplace+double(r);
                end
            end
            bankAge=bankAge+1; bankEvalCount=bankEvalCount+count;
        end
    end

    goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved);
    gainFull=zeros(sizepop,1); gainFull(improved)=gain;
    archive=unique([archive;pop(improved,:)],'rows');
    if size(archive,1)>archiveCapacity
        archive=archive(randperm(size(archive,1),archiveCapacity),:);
    end
    pop(accepted,:)=trial(accepted,:);
    fitness(accepted)=values(accepted);
    stallCount(accepted)=0;
    notAccepted=~accepted; notAccepted(count+1:end)=false;
    stallCount(notAccepted)=stallCount(notAccepted)+1;

    if isOff
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
    else
        for op=1:2
            sel=improved(1:count) & src(1:count)==op;
            if op==1, pos=memoryPos; else, pos=memoryPos2; end
            if any(sel)
                ss=find(sel); g=gainFull(ss); weights=g/sum(g);
                fs=F(ss); crs=CR(ss);
                if op==1
                    memoryF(pos)=sum(weights.*fs.^2)/sum(weights.*fs);
                    if max(crs)==0 || memoryCR(pos)==-1
                        memoryCR(pos)=-1;
                    else
                        memoryCR(pos)=sum(weights.*crs.^2)/sum(weights.*crs);
                    end
                    memoryPos=mod(memoryPos,memorySize)+1;
                else
                    memoryF2(pos)=sum(weights.*fs.^2)/sum(weights.*fs);
                    if max(crs)==0 || memoryCR2(pos)==-1
                        memoryCR2(pos)=-1;
                    else
                        memoryCR2(pos)=sum(weights.*crs.^2)/sum(weights.*crs);
                    end
                    memoryPos2=mod(memoryPos2,memorySize)+1;
                end
            end
        end
        if isAdaptive
            nCountN=max(1,sum(src(1:count)==2)); nCountB=max(1,sum(src(1:count)==1));
            emaN=0.9*emaN+0.1*(sum(improved(1:count)&src(1:count)==2)/nCountN);
            emaB=0.9*emaB+0.1*(sum(improved(1:count)&src(1:count)==1)/nCountB);
            ratio=emaN/(emaN+emaB+1e-12);
            if ratio>=0.5
                pAdapt=ecoBaseProb+(ecoMaxProb-ecoBaseProb)*min(1,2*(ratio-0.5));
            else
                pAdapt=ecoBaseProb-(ecoBaseProb-ecoMinProb)*min(1,2*(0.5-ratio));
            end
            pAdapt=min(ecoMaxProb,max(ecoMinProb,pAdapt));
        else
            pAdapt=ecoBaseProb;
        end
    end

    if Best.Cost<genBestBefore
        lastGB=info.Evaluations;
    end
    plannedSize=max(minSize,round(initialSize+(minSize-initialSize)*info.Evaluations/budget));
    if sizepop>plannedSize
        [~,order]=sort(fitness);
        pop=pop(order(1:plannedSize),:); fitness=fitness(order(1:plannedSize));
        stallCount=stallCount(order(1:plannedSize));
        sizepop=plannedSize; archiveCapacity=round(archiveRate*sizepop);
        if size(archive,1)>archiveCapacity
            archive=archive(randperm(size(archive,1),archiveCapacity),:);
        end
    end
    info.PopulationHistory(end+1)=sizepop;
    info.ArchiveSizeHistory(end+1)=size(archive,1);
end

info.Algorithm='NELSHADE'; info.Rounds=max(0,numel(info.PopulationHistory)-1);
info.Seed=seed; info.MemoryF=memoryF; info.MemoryCR=memoryCR;
info.MemoryF2=memoryF2; info.MemoryCR2=memoryCR2;
info.FinalPopulationSize=sizepop; info.FinalPopulation=pop; info.FinalFitness=fitness;
info.FinalArchive=archive; info.FinalNicheBank=bankX; info.FinalNicheFitness=bankF;
info.EcoMode=ecoMode; info.EcoOn=double(~isOff); info.EcoAdaptive=double(isAdaptive);
info.EcoNicheBankSize=size(bankX,1); info.EcoNicheBankMax=ecoNicheCap;
info.EcoNicheAdmits=nBankAdmit; info.EcoNicheReplaces=nBankReplace;
info.EcoBankEval=bankEvalCount; info.EcoGens=ecoGens; info.EcoStagGens=stagGens;
info.EcoNicheSrcGen=nicheSrcGen; info.EcoNicheEval=nicheEvalCount;
info.EcoBaseEval=baseEvalCount; info.EcoNicheSuccess=nicheSuccCount;
info.EcoBaseSuccess=baseSuccCount;
info.EcoNicheEvalRate=nicheEvalCount/max(nicheEvalCount+baseEvalCount,1);
info.EcoNicheSuccessRate=nicheSuccCount/max(nicheEvalCount,1);
info.EcoBaseSuccessRate=baseSuccCount/max(baseEvalCount,1);
info.EcoPFinal=pNiche; info.EcoPMean=mean(pTrace); info.EcoPMax=max(pTrace);
info.EcoTrace=pTrace; info.Seconds=toc(clockStart);
end

function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop;
r1=floor(rand(1,sizepop)*sizepop)+1;
bad=r1==r0;
while any(bad)
    r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0;
end
r2=floor(rand(1,sizepop)*poolSize)+1;
bad=r2==r0 | r2==r1;
while any(bad)
    r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0 | r2==r1;
end
end

function [X,Fv,Age,admit,replaced]=bankAdmit(X,Fv,Age,x,v,cap,sep,span)
admit=false; replaced=false;
if isempty(X)
    X=x; Fv=v; Age=0; admit=true; return;
end
d=sqrt(sum((X-repmat(x,size(X,1),1)).^2,2))/span;
[dmin,ni]=min(d);
if dmin>=sep
    if size(X,1)<cap
        X(end+1,:)=x; Fv(end+1,1)=v; Age(end+1,1)=0; admit=true;
    else
        [worst,wi]=max(Fv);
        if v<worst
            X(wi,:)=x; Fv(wi)=v; Age(wi)=0; admit=true; replaced=true;
        end
    end
elseif v<Fv(ni)
    X(ni,:)=x; Fv(ni)=v; Age(ni)=0; admit=true; replaced=true;
end
end

function Best=UpdateBest(Best,vector,cost)
if cost<Best.Cost
    Best.Vector=vector; Best.Cost=cost;
end
end
