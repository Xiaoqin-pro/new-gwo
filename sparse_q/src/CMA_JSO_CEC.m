function [Best,T,info]=CMA_JSO_CEC(f,state,~,N,seed)
%CMA_JSO_CEC  CMA main search followed by a short jSO refinement phase.
%   The CMA global best is retained, so the post-refinement phase can only
%   improve the returned incumbent.  A small random component supplies the
%   diversity that a collapsed CMA covariance cannot provide to jSO.
if ~isfield(state,'cmaJsoFraction') || isempty(state.cmaJsoFraction), state.cmaJsoFraction=0.90; end
mixFrac=0.20; if isfield(state,'cmaJsoMix') && ~isempty(state.cmaJsoMix), mixFrac=min(1,max(0,state.cmaJsoMix)); end
budget=state.maxEvaluations; Bc=round(state.cmaJsoFraction*budget); Bj=budget-Bc;
assert(Bc>=N && Bj>=N);
s1=state; s1.maxEvaluations=Bc;
[BcBest,Tc,ic]=CMAES_CEC(f,s1,[],N,seed+111111);
cma=ic.FinalCMAState; [V,L]=eig((cma.C+cma.C')/2); L=max(diag(L),1e-14);
Z=randn(N,size(cma.Mean,2));
X=repmat(cma.Mean,N,1)+cma.Sigma*(Z*(V*diag(sqrt(L)))');
nMix=round(mixFrac*N);
if nMix>0
    X(1:nMix,:)=repmat(state.lowerBound,nMix,1)+rand(nMix,numel(state.lowerBound)).*repmat(state.upperBound-state.lowerBound,nMix,1);
end
if nMix==0 || mixFrac==0, X(1,:)=BcBest.Vector; else, X(end,:)=BcBest.Vector; end
X=reflectBounds(X,state.lowerBound,state.upperBound);
s2=state; s2.maxEvaluations=Bj; s2.initialPopulation=X;
[BjBest,Tj,ij]=jSO_CEC(f,s2,[],N,seed+777777);
if BjBest.Cost<BcBest.Cost, Best=BjBest; else, Best=BcBest; end
T=[min(Tc(:),Best.Cost);min(Tj(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info.Algorithm='CMA-JSO'; info.Evaluations=budget; info.Rounds=ic.Rounds+ij.Rounds;
info.CMAFE=Bc; info.JSOFE=Bj; info.CMABest=BcBest.Cost; info.JSOBest=BjBest.Cost;
info.CMAFraction=state.cmaJsoFraction; info.MixFraction=mixFrac;
info.CMAInfo=ic; info.JSOInfo=ij;
end
function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
    low=X<lo; high=X>hi; if ~any(low(:)|high(:)), break; end
    X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end
