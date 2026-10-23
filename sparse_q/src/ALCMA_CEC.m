function [Best,T,info]=ALCMA_CEC(f,state,~,N,seed)
%ALCMA_CEC  CMA-ES with stagnation-triggered population expansion.
budget=state.maxEvaluations; block=max(2*N,round(0.10*budget)); tol=5e-4; patience=2;
patience=2; if isfield(state,'alcPatience') && ~isempty(state.alcPatience), patience=state.alcPatience; end
if isfield(state,'alcTol') && ~isempty(state.alcTol), tol=state.alcTol; end
used=0; Tparts=cell(0,1); bestStart=inf; stagn=0; switched=false; switchFE=NaN; lambdaNow=N;
s=state; s.maxEvaluations=min(block,budget); [Best,Tb,ib]=CMAES_CEC(f,s,[],N,seed+111111);
Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; bestStart=Best.Cost;
while used<budget
    rem=budget-used; b=min(block,rem); if b<lambdaNow, break; end
    s=state; s.maxEvaluations=b; s.cmaState=cmaState; [B,Tb,ib]=CMAES_RESUME(f,s,[],lambdaNow,seed+111111+used);
    Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState;
    if B.Cost<Best.Cost, Best=B; end
    rel=(bestStart-Best.Cost)/max(abs(bestStart),1); if rel<tol, stagn=stagn+1; else, stagn=0; end
    bestStart=Best.Cost;
    if stagn>=patience && ~switched
        lambdaNow=100; switched=true; switchFE=used; stagn=0;
    end
end
T=zeros(0,1); for k=1:numel(Tparts), T=[T;Tparts{k}(:)]; end %#ok<AGROW>
T=min(T,Best.Cost); T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='AL-CMA'; info.Evaluations=budget; info.Rounds=used; info.Switched=double(switched);
info.SwitchFE=switchFE; info.FinalLambda=lambdaNow; info.BlockFE=block; info.Tol=tol; info.Patience=patience; info.FinalCMAState=cmaState;
end
