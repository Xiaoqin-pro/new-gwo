function [Best,T,info]=CMA_LS_CEC(f,state,~,N,seed)
%CMA_LS_CEC  CMA-ES followed by a fresh L-SHADE population sampled from its final distribution.
if ~isfield(state,'cmaFraction') || isempty(state.cmaFraction), state.cmaFraction=0.80; end
budget=state.maxEvaluations; Bc=round(state.cmaFraction*budget); Bl=budget-Bc;
assert(Bc>=N && Bl>=N);
s1=state; s1.maxEvaluations=Bc; [BcBest,Tc,ic]=CMAES_CEC(f,s1,[],N,seed+111111);
cma=ic.FinalCMAState; [V,L]=eig((cma.C+cma.C')/2); L=max(diag(L),1e-14);
Z=randn(N,size(cma.Mean,2)); X=repmat(cma.Mean,N,1)+cma.Sigma*(Z*(V*diag(sqrt(L)))');
mixFrac=0; if isfield(state,'cmaLsMix') && ~isempty(state.cmaLsMix), mixFrac=min(1,max(0,state.cmaLsMix)); end
nMix=round(mixFrac*N); if nMix>0, X(1:nMix,:)=-100+200*rand(nMix,size(X,2)); end
if nMix>=N, X(1,:)=BcBest.Vector; else, X(end,:)=BcBest.Vector; end
X=reflectBounds(X,state.lowerBound,state.upperBound);
s2=state; s2.maxEvaluations=Bl; s2.initialPopulation=X; s2.initialBest=BcBest;
[BlBest,Tl,il]=LSHADE_CEC(f,s2,[],N,seed+777777);
if BlBest.Cost<BcBest.Cost, Best=BlBest; else, Best=BcBest; end
T=[min(Tc(:),Best.Cost);min(Tl(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info=struct('Algorithm','CMA-LS','Evaluations',budget,'Rounds',ic.Rounds+il.Rounds, ...
 'CMAESFE',Bc,'LSHADEFE',Bl,'CMAESBest',BcBest.Cost,'LSHADEBest',BlBest.Cost, ...
 'CMAFraction',state.cmaFraction,'CMAESInfo',ic,'LSHADEInfo',il);
end
function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
 low=X<lo; high=X>hi; if ~any(low(:)|high(:)), break; end
 X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end
