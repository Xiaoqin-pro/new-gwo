function [Best,T,info]=LSHADE_CML_CEC(f,state,~,N,seed)
%LSHADE_CML_CEC  L-SHADE with covariance-rotated differential mutation.
clockStart=tic; pop=state.initialPopulation; D=size(pop,2); sizepop=N; initialSize=sizepop; minSize=4;
pBestRate=0.11; archiveRate=1.4; memorySize=5; lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations; assert(sizepop>=4 && budget>=sizepop); rng(seed,'twister');
cmlFrac=0.5; if isfield(state,'cmlFrac') && ~isempty(state.cmlFrac), cmlFrac=min(0.9,max(0,state.cmlFrac)); end
cmlEvery=10; if isfield(state,'cmlEvery') && ~isempty(state.cmlEvery), cmlEvery=max(2,round(state.cmlEvery)); end
T=nan(budget,1); fitness=zeros(sizepop,1); Best.Cost=inf;
for i=1:sizepop, fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost; end
used=sizepop; memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1); memoryPos=1; archive=zeros(0,D); archiveCap=round(archiveRate*sizepop); V=eye(D); ctr=zeros(1,D); rounds=0;
while used<budget
 rounds=rounds+1; [~,order]=sort(fitness);
 if mod(rounds-1,cmlEvery)==0 && rounds>1
  nTop=max(4,round(0.5*sizepop)); Xtop=pop(order(1:min(nTop,sizepop)),:); ctr=mean(Xtop,1); if size(Xtop,1)>=2 && D>1, Cm=cov(Xtop); [V,L]=eig((Cm+Cm')/2); [~,eo]=sort(diag(L),'descend'); V=V(:,eo); else V=eye(D); ctr=zeros(1,D); end
 end
 memoryIndex=ceil(memorySize*rand(sizepop,1)); muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
 CR=muCR+0.1*randn(sizepop,1); CR(muCR==-1)=0; CR=max(0,min(1,CR));
 F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5)); bad=find(F<=0); while ~isempty(bad), F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5)); bad=find(F<=0); end; F=min(1,F);
 pool=[pop;archive]; [r1,r2]=RandomParents(sizepop,size(pool,1)); pCount=max(round(pBestRate*sizepop),2); pIndex=max(1,ceil(rand(1,sizepop)*pCount)); pbest=pop(order(pIndex),:);
 mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
 if cmlFrac>0 && rounds>1
  nC=max(1,round(cmlFrac*sizepop)); idx=1:nC; Zp=(pop(idx,:)-repmat(ctr,nC,1))*V; Zb=(pbest(idx,:)-repmat(ctr,nC,1))*V; Zr=(pop(r1(idx),:)-repmat(ctr,nC,1))*V; Za=(pool(r2(idx),:)-repmat(ctr,nC,1))*V; Zm=Zp+F(idx).*(Zb-Zp+Zr-Za); mutant(idx,:)=Zm*V'+repmat(ctr,nC,1);
 end
 low=repmat(lb,sizepop,1); up=repmat(ub,sizepop,1); out=mutant<low; mutant(out)=(pop(out)+low(out))/2; out=mutant>up; mutant(out)=(pop(out)+up(out))/2;
 mask=rand(sizepop,D)>CR; jr=sub2ind([sizepop D],(1:sizepop)',floor(rand(sizepop,1)*D)+1); mask(jr)=false; trial=mutant; trial(mask)=pop(mask);
 count=min(sizepop,budget-used); values=fitness;
 for i=1:count, values(i)=f(trial(i,:)); used=used+1; Best=UpdateBest(Best,trial(i,:),values(i)); T(used)=Best.Cost; end
 improved=values<fitness; goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved); archive=unique([archive;pop(improved,:)],'rows'); if size(archive,1)>archiveCap, archive=archive(randperm(size(archive,1),archiveCap),:); end; accepted=false(sizepop,1); accepted(1:count)=values(1:count)<fitness(1:count); pop(accepted,:)=trial(accepted,:); fitness(accepted)=values(accepted);
 if ~isempty(goodF), w=gain/sum(gain); memoryF(memoryPos)=sum(w.*goodF.^2)/sum(w.*goodF); if max(goodCR)==0||memoryCR(memoryPos)==-1, memoryCR(memoryPos)=-1; else memoryCR(memoryPos)=sum(w.*goodCR.^2)/sum(w.*goodCR); end; memoryPos=mod(memoryPos,memorySize)+1; end
 planned=max(minSize,round(initialSize+(minSize-initialSize)*used/budget)); if sizepop>planned, [~,order]=sort(fitness); pop=pop(order(1:planned),:); fitness=fitness(order(1:planned)); sizepop=planned; archiveCap=round(archiveRate*sizepop); if size(archive,1)>archiveCap, archive=archive(randperm(size(archive,1),archiveCap),:); end; end
end
info.Algorithm='LSHADE-CML'; info.Evaluations=used; info.Rounds=rounds; info.FinalPopulation=pop; info.FinalFitness=fitness; info.FinalArchive=archive; info.FinalPopulationSize=sizepop; info.CMLFrac=cmlFrac; info.CMLEvery=cmlEvery; info.Seconds=toc(clockStart);
end
function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop; r1=floor(rand(1,sizepop)*sizepop)+1; bad=r1==r0; while any(bad), r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0; end; r2=floor(rand(1,sizepop)*poolSize)+1; bad=r2==r0|r2==r1; while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0|r2==r1; end
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
