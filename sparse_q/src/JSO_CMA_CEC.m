function [Best,T,info]=JSO_CMA_CEC(f,state,~,N,seed)
if ~isfield(state,'jsoFrac') || isempty(state.jsoFrac), state.jsoFrac=0.50; end
budget=state.maxEvaluations; B1=round(state.jsoFrac*budget); B2=budget-B1; assert(B1>=N && B2>=N);
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=jSO_CEC(f,s1,[],N,seed+111111);
X=i1.FinalPopulation; if size(X,1)<N
 F=i1.FinalArchive; if ~isempty(F), X=unique([X;F],'rows','stable'); end
 if size(X,1)<N, X=[X;state.initialPopulation(1:N-size(X,1),:)]; end
end
if size(X,1)>N, X=X(1:N,:); end
s2=state; s2.maxEvaluations=B2; s2.initialPopulation=X; s2.initialBest=B1best;
[B2best,T2,i2]=CMAES_CEC(f,s2,[],N,seed+777777);
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
T=[min(T1(:),Best.Cost);min(T2(:),Best.Cost)]; T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='JSO-CMA'; info.Evaluations=budget; info.Rounds=i1.Rounds+i2.Rounds; info.jSOFE=B1; info.CMAFE=B2; info.jSOBest=B1best.Cost; info.CMABest=B2best.Cost; info.InitPop=size(X,1); info.JSOInfo=i1; info.CMAInfo=i2;
end
