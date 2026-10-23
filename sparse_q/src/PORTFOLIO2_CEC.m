function [Best,T,info]=PORTFOLIO2_CEC(f,state,~,N,seed)
%PORTFOLIO2_CEC  Independent CMA-ES and jSO cores with a shared output.
if ~isfield(state,'p2Split') || isempty(state.p2Split), state.p2Split=0.50; end
frac=min(0.90,max(0.10,state.p2Split)); budget=state.maxEvaluations; Bc=round(frac*budget); Bj=budget-Bc; assert(Bc>=N && Bj>=N);
s1=state; s1.maxEvaluations=Bc; [BcBest,Tc,ic]=CMAES_CEC(f,s1,[],N,seed+111111);
s2=state; s2.maxEvaluations=Bj; [BjBest,Tj,ij]=jSO_CEC(f,s2,[],N,seed+777777);
if BjBest.Cost<BcBest.Cost, Best=BjBest; else, Best=BcBest; end
T=[min(Tc(:),Best.Cost);min(Tj(:),Best.Cost)]; T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='PORTFOLIO2'; info.Evaluations=budget; info.Rounds=ic.Rounds+ij.Rounds; info.CMAESFE=Bc; info.jSOFE=Bj; info.CMAESBest=BcBest.Cost; info.jSOBest=BjBest.Cost; info.Split=frac; info.CMAInfo=ic; info.JSOInfo=ij;
end
