function [Best,T,info]=PORTFOLIO_CEC(f,state,~,N,seed)
%PORTFOLIO_CEC  Independent dual-core portfolio: CMA-ES + L-SHADE.
%   Both cores start from the same verified initial pool but retain their
%   own population, covariance, archive, and F/CR memory.  No state is
%   transferred between them; only the final best is shared.  The split is
%   in true FE, so total FE remains exactly the requested budget.
if ~isfield(state,'portfolioSplit') || isempty(state.portfolioSplit), state.portfolioSplit=0.50; end
frac=min(0.90,max(0.10,state.portfolioSplit)); budget=state.maxEvaluations;
Bc=round(frac*budget); Bl=budget-Bc;
assert(Bc>=N && Bl>=N,'portfolio split leaves a core below N evaluations');
s1=state; s1.maxEvaluations=Bc;
[BcBest,Tc,ic]=CMAES_CEC(f,s1,[],N,seed+111111);
s2=state; s2.maxEvaluations=Bl;
[BlBest,Tl,il]=LSHADE_CEC(f,s2,[],N,seed+777777);
if BlBest.Cost<BcBest.Cost, Best=BlBest; else, Best=BcBest; end
baseBest=min(BcBest.Cost,BlBest.Cost);
T=[min(Tc(:),baseBest);min(Tl(:),baseBest)];
T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
assert(T(end)==Best.Cost,'portfolio trace endpoint mismatch');
info=struct('Algorithm','PORTFOLIO','Evaluations',budget, ...
    'Rounds',ic.Rounds+il.Rounds,'CMAESFE',Bc,'LSHADEFE',Bl, ...
    'CMAESBest',BcBest.Cost,'LSHADEBest',BlBest.Cost, ...
    'PortfolioSplit',frac,'CMAESInfo',ic,'LSHADEInfo',il);
end
