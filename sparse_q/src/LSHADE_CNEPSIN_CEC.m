function [Best,T,info]=LSHADE_CNEPSIN_CEC(f,state,~,N,seed)
%LSHADE_CNEPSIN_CEC  LSHADE with eigen-coordinate crossover in a best-neighborhood.
clockStart=tic; pop=state.initialPopulation; D=size(pop,2); sizepop=N; initialSize=sizepop; minSize=4;
pBestRate=0.11; archiveRate=1.4; memorySize=5; lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations; assert(sizepop>=4 && budget>=sizepop); rng(seed,'twister');
pb=0.4; if isfield(state,'cnePb') && ~isempty(state.cnePb), pb=min(1,max(0,state.cnePb)); end
T=nan(budget,1); fitness=zeros(sizepop,1); Best.Cost=inf;
for i=1:sizepop, fitness(i)=f(pop(i,:)); Best=UpdateBest(Best,pop(i,:),fitness(i)); T(i)=Best.Cost; end
used=sizepop; memoryF=0.5*ones(memorySize,1); memoryCR=0.5*ones(memorySize,1); memoryPos=1; archive=zeros(0,D); archiveCap=round(archiveRate*sizepop); rounds=0;
while used<budget
 rounds=rounds+1; [~,order]=sort(fitness); memoryIndex=ceil(memorySize*rand(sizepop,1)); muF=memoryF(memoryIndex); muCR=memoryCR(memoryIndex);
 CR=muCR+0.1*randn(sizepop,1); CR(muCR==-1)=0; CR=max(0,min(1,CR)); F=muF+0.1*tan(pi*(rand(sizepop,1)-0.5)); bad=find(F<=0); while ~isempty(bad), F(bad)=muF(bad)+0.1*tan(pi*(rand(numel(bad),1)-0.5)); bad=find(F<=0); end; F=min(1,F);
 pool=[pop;archive]; [r1,r2]=RandomParents(sizepop,size(pool,1)); pCount=max(round(pBestRate*sizepop),2); pIndex=max(1,ceil(rand(1,sizepop)*pCount)); pbest=pop(order(pIndex),:); mutant=pop+F.*(pbest-pop+pop(r1,:)-pool(r2,:));
 low=repmat(lb,sizepop,1); up=repmat(ub,sizepop,1); out=mutant<low; mutant(out)=(pop(out)+low(out))/2; out=mutant>up; mutant(out)=(pop(out)+up(out))/2;
 jr=floor(rand(sizepop,1)*D)+1; crs=rand(sizepop,D)<=CR; jlin=sub2ind([sizepop D],(1:sizepop)',jr); crs(jlin)=true;
 if rand<pb
  best=pop(order(1),:); dist=sqrt(sum((pop-repmat(best,sizepop,1)).^2,2)); [~,near]=sort(dist); sel=max(4,round(0.5*sizepop)); Xsel=pop(near(1:min(sel,sizepop)),:); xm=mean(Xsel,1); Cc=cov(Xsel); if any(~isfinite(Cc(:))), R=eye(D); else [R,L]=eig((Cc+Cc')/2); if any(~isfinite(L(:))), R=eye(D); end; end
  Xr=pop*R; Vr=mutant*R; Ur=Xr; Ur(crs)=Vr(crs); Ur(jlin)=Vr(jlin); trial=Ur*R';
 else
  trial=pop; trial(crs)=mutant(crs); trial(jlin)=mutant(jlin);
 end
 trial=boundConstraint(trial,pop,lb,ub);
 count=min(sizepop,budget-used); values=fitness; for i=1:count, values(i)=f(trial(i,:)); used=used+1; Best=UpdateBest(Best,trial(i,:),values(i)); T(used)=Best.Cost; end
 improved=values<fitness; goodF=F(improved); goodCR=CR(improved); gain=fitness(improved)-values(improved); archive=unique([archive;pop(improved,:)],'rows'); if size(archive,1)>archiveCap, archive=archive(randperm(size(archive,1),archiveCap),:); end; accepted=false(sizepop,1); accepted(1:count)=values(1:count)<fitness(1:count); pop(accepted,:)=trial(accepted,:); fitness(accepted)=values(accepted);
 if ~isempty(goodF), w=gain/sum(gain); memoryF(memoryPos)=sum(w.*goodF.^2)/sum(w.*goodF); if max(goodCR)==0||memoryCR(memoryPos)==-1, memoryCR(memoryPos)=-1; else memoryCR(memoryPos)=sum(w.*goodCR.^2)/sum(w.*goodCR); end; memoryPos=mod(memoryPos,memorySize)+1; end
 planned=max(minSize,round(initialSize+(minSize-initialSize)*used/budget)); if sizepop>planned, [~,order]=sort(fitness); pop=pop(order(1:planned),:); fitness=fitness(order(1:planned)); sizepop=planned; archiveCap=round(archiveRate*sizepop); if size(archive,1)>archiveCap, archive=archive(randperm(size(archive,1),archiveCap),:); end; end
end
info.Algorithm='LSHADE-CNEPSIN'; info.Evaluations=used; info.Rounds=rounds; info.FinalPopulation=pop; info.FinalFitness=fitness; info.FinalArchive=archive; info.FinalPopulationSize=sizepop; info.Pb=pb; info.Seconds=toc(clockStart);
end
function [r1,r2]=RandomParents(sizepop,poolSize)
r0=1:sizepop; r1=floor(rand(1,sizepop)*sizepop)+1; bad=r1==r0; while any(bad), r1(bad)=floor(rand(1,sum(bad))*sizepop)+1; bad=r1==r0; end; r2=floor(rand(1,sizepop)*poolSize)+1; bad=r2==r0|r2==r1; while any(bad), r2(bad)=floor(rand(1,sum(bad))*poolSize)+1; bad=r2==r0|r2==r1; end
end
function X=boundConstraint(X,pop,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); out=X<lo; X(out)=(pop(out)+lo(out))/2; out=X>hi; X(out)=(pop(out)+hi(out))/2;
end
function Best=UpdateBest(Best,v,c)
if c<Best.Cost, Best.Vector=v; Best.Cost=c; end
end
