function [Best,T,info]=DAR_CMA_CEC(f,state,~,N,seed)
%DAR_CMA_CEC  CMA-ES with verified diversity-archive restart on plateau.
budget=state.maxEvaluations; block=max(2*N,round(0.20*budget)); tol=5e-4;
if isfield(state,'darTol') && ~isempty(state.darTol), tol=state.darTol; end
forceRestart=false; if isfield(state,'darForceRestart') && ~isempty(state.darForceRestart), forceRestart=logical(state.darForceRestart); end
used=0; Tparts=cell(0,1); archiveX=zeros(0,size(state.initialPopulation,2)); archiveF=zeros(0,1);
s=state; s.maxEvaluations=min(block,budget); [Best,Tb,ib]=CMAES_CEC(f,s,[],N,seed+111111);
Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; [archiveX,archiveF]=addArchive(archiveX,archiveF,Best.Vector,Best.Cost);
restarts=0; triggerFE=zeros(0,1); bestStart=Best.Cost;
while used<budget
    rem=budget-used; b=min(block,rem); if b<N, break; end
    rel=(bestStart-Best.Cost)/max(abs(bestStart),1);
    doRestart=forceRestart || rel<tol;
    if doRestart
        base=chooseArchive(archiveX,archiveF,Best.Vector);
        X=makeRestartPool(base,N,state.lowerBound,state.upperBound);
        s=state; s.maxEvaluations=b; s.initialPopulation=X;
        [B,Tb,ib]=CMAES_CEC(f,s,[],N,seed+333333+used);
        restarts=restarts+1; triggerFE(end+1,1)=used; %#ok<AGROW>
    else
        s=state; s.maxEvaluations=b; s.cmaState=cmaState;
        [B,Tb,ib]=CMAES_RESUME(f,s,[],N,seed+111111+used);
    end
    Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState;
    if B.Cost<Best.Cost, Best=B; end
    [archiveX,archiveF]=addArchive(archiveX,archiveF,Best.Vector,Best.Cost);
    bestStart=Best.Cost;
end
T=zeros(0,1); for k=1:numel(Tparts), T=[T;Tparts{k}(:)]; end %#ok<AGROW>
T=min(T,Best.Cost); T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='DAR-CMA'; info.Evaluations=budget; info.Rounds=used; info.Restarts=restarts;
info.TriggerFE=triggerFE; info.ArchiveSize=size(archiveX,1); info.Tol=tol; info.BlockFE=block; info.FinalCMAState=cmaState;
end
function [X,F]=addArchive(X,F,x,v)
cap=20;
if isempty(X), X=x; F=v; return; end
if any(all(abs(X-repmat(x,size(X,1),1))<1e-14,2)), return; end
if size(X,1)<cap
    X(end+1,:)=x; F(end+1,1)=v;
else
    [worst,wi]=max(F); if v<worst, X(wi,:)=x; F(wi)=v; end
end
end
function base=chooseArchive(X,F,best)
if isempty(X), base=best; return; end
[~,ord]=sort(F); top=ord(1:min(numel(ord),max(2,ceil(0.5*numel(ord)))));
d=sqrt(sum((X(top,:)-repmat(best,numel(top),1)).^2,2)); [~,i]=max(d); base=X(top(i),:);
end
function X=makeRestartPool(base,N,lb,ub)
D=numel(base); nmax=max(2,round(0.5*N)); G=base+20*randn(nmax,D);
U=-100+200*rand(N-nmax,D); X=[G;U];
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
