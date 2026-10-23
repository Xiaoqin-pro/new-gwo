function [Best,T,info]=REHEAT_CMA_CEC(f,state,~,N,seed)
%REHEAT_CMA_CEC  CMA-ES with stagnation-triggered sigma inflation only.
budget=state.maxEvaluations; block=max(2*N,round(0.10*budget)); tol=5e-4; patience=2;
if isfield(state,'rhPatience') && ~isempty(state.rhPatience), patience=state.rhPatience; end
if isfield(state,'rhTol') && ~isempty(state.rhTol), tol=state.rhTol; end
if isfield(state,'rhFactor') && ~isempty(state.rhFactor), factor=state.rhFactor; else, factor=2; end
used=0; Tparts=cell(0,1); bestStart=inf; stagn=0; reheats=0; reheatFE=zeros(0,1);
s=state; s.maxEvaluations=min(block,budget); [Best,Tb,ib]=CMAES_CEC(f,s,[],N,seed+111111);
Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; bestStart=Best.Cost;
while used<budget
 rem=budget-used; b=min(block,rem); if b<N, break; end
 s=state; s.maxEvaluations=b; s.cmaState=cmaState; [B,Tb,ib]=CMAES_RESUME(f,s,[],N,seed+111111+used);
 Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; if B.Cost<Best.Cost, Best=B; end
 rel=(bestStart-Best.Cost)/max(abs(bestStart),1); if rel<tol, stagn=stagn+1; else, stagn=0; end; bestStart=Best.Cost;
 if stagn>=patience
  cmaState.Sigma=min(80,max(cmaState.Sigma*factor,5)); stagn=0; reheats=reheats+1; reheatFE(end+1,1)=used; %#ok<AGROW>
 end
end
T=zeros(0,1); for k=1:numel(Tparts), T=[T;Tparts{k}(:)]; end %#ok<AGROW>
T=min(T,Best.Cost); T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='REHEAT-CMA'; info.Evaluations=budget; info.Rounds=used; info.Reheats=reheats; info.ReheatFE=reheatFE; info.FinalSigma=cmaState.Sigma; info.Tol=tol; info.Patience=patience; info.FinalCMAState=cmaState;
end
