function [Best,T,info]=CMA_GATED_CEC(f,state,~,N,seed)
%CMA_GATED_CEC  Stagnation-gated CMA -> jSO cross-paradigm handoff.
%   CMA runs to a phase checkpoint.  If recent relative progress is below a
%   threshold, a distribution-aware jSO refinement is launched for the rest
%   of the budget.  Otherwise the verified CMA state is resumed unchanged.
if ~isfield(state,'cmaGateFraction') || isempty(state.cmaGateFraction), state.cmaGateFraction=0.80; end
if ~isfield(state,'cmaGateTol') || isempty(state.cmaGateTol), state.cmaGateTol=1e-4; end
window=10000; if isfield(state,'cmaGateWindow') && ~isempty(state.cmaGateWindow), window=max(100,round(state.cmaGateWindow)); end
mixFrac=0.20; if isfield(state,'cmaGateMix') && ~isempty(state.cmaGateMix), mixFrac=min(1,max(0,state.cmaGateMix)); end
budget=state.maxEvaluations; Bc=round(state.cmaGateFraction*budget); remFE=budget-Bc;
assert(Bc>=N && remFE>=N);
s1=state; s1.maxEvaluations=Bc; [BcBest,Tc,ic]=CMAES_CEC(f,s1,[],N,seed+111111);
k=max(1,Bc-window); recentBase=Tc(k); recentProgress=(recentBase-BcBest.Cost)/max(1,abs(recentBase));
doHandoff=recentProgress<=state.cmaGateTol;
if doHandoff
    cma=ic.FinalCMAState; [V,L]=eig((cma.C+cma.C')/2); L=max(diag(L),1e-14);
    Z=randn(N,size(cma.Mean,2));
    X=repmat(cma.Mean,N,1)+cma.Sigma*(Z*(V*diag(sqrt(L)))');
    nMix=round(mixFrac*N);
    if nMix>0
        X(1:nMix,:)=repmat(state.lowerBound,nMix,1)+rand(nMix,numel(state.lowerBound)).*repmat(state.upperBound-state.lowerBound,nMix,1);
    end
    if nMix>=N, X(1,:)=BcBest.Vector; else, X(end,:)=BcBest.Vector; end
    X=reflectBounds(X,state.lowerBound,state.upperBound);
    s2=state; s2.maxEvaluations=remFE; s2.initialPopulation=X;
    [B2Best,T2,i2]=jSO_CEC(f,s2,[],N,seed+777777);
    refine='jSO';
else
    s2=state; s2.maxEvaluations=remFE; s2.cmaState=ic.FinalCMAState;
    [B2Best,T2,i2]=CMAES_RESUME(f,s2,[],N,seed+333333+Bc);
    refine='CMA';
end
if B2Best.Cost<BcBest.Cost, Best=B2Best; else, Best=BcBest; end
T=[min(Tc(:),Best.Cost);min(T2(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info.Algorithm='CMA-GATED'; info.Evaluations=budget; info.Rounds=ic.Rounds+i2.Rounds;
info.CMAFE=Bc; info.RefineFE=remFE; info.CMABest=BcBest.Cost; info.RefineBest=B2Best.Cost;
info.CMAFraction=state.cmaGateFraction; info.Handoff=double(doHandoff); info.Refine=refine;
info.RecentProgress=recentProgress; info.GateTol=state.cmaGateTol; info.GateWindow=window; info.MixFraction=mixFrac;
info.CMAInfo=ic; info.RefineInfo=i2;
end
function X=reflectBounds(X,lb,ub)
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1);
for k=1:8
    low=X<lo; high=X>hi; if ~any(low(:)|high(:)), break; end
    X(low)=2*lo(low)-X(low); X(high)=2*hi(high)-X(high);
end
X=max(min(X,hi),lo);
end
