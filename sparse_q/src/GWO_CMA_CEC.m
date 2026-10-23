function [Best,T,info]=GWO_CMA_CEC(f,state,~,N,seed)
%GWO_CMA_CEC  G1+E+STEER diversity front-end followed by CMA refinement.
if ~isfield(state,'gwoFrac') || isempty(state.gwoFrac), state.gwoFrac=0.30; end
budget=state.maxEvaluations; B1=round(state.gwoFrac*budget); B2=budget-B1; assert(B1>=N && B2>=N);
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=SGWO_STEER3(f,s1,[],N,seed+111111);
X=i1.FinalPopulation; if isempty(X) || size(X,1)<2, X=state.initialPopulation; end
if size(X,1)>N, X=X(1:N,:); end
s2=state; s2.maxEvaluations=B2; s2.initialPopulation=X; s2.initialBest=B1best;
[B2best,T2,i2]=CMAES_CEC(f,s2,[],N,seed+777777);
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
T=[min(T1(:),Best.Cost);min(T2(:),Best.Cost)]; T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='GWO-CMA'; info.Evaluations=budget; info.Rounds=i1.Rounds+i2.Rounds;
info.GWOFE=B1; info.CMAFE=B2; info.GWOBest=B1best.Cost; info.CMABest=B2best.Cost;
info.GWOPopSize=size(X,1); info.GWOInfo=i1; info.CMAInfo=i2;
end
