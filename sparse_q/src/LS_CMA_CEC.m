function [Best,T,info]=LS_CMA_CEC(f,state,~,N,seed)
if ~isfield(state,'lsFrac') || isempty(state.lsFrac), state.lsFrac=0.70; end
budget=state.maxEvaluations; B1=round(state.lsFrac*budget); B2=budget-B1; assert(B1>=N && B2>=N);
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=LSHADE_CEC(f,s1,[],N,seed+111111);
X=i1.FinalPopulation; if size(X,1)<2, X=state.initialPopulation; end
if size(X,1)<N
    Filler=i1.FinalArchive; if ~isempty(Filler), X=unique([X;Filler],'rows','stable'); end
    if size(X,1)<N
        need=N-size(X,1); X=[X;state.initialPopulation(1:need,:)];
    end
end
if size(X,1)>N, X=X(1:N,:); end
s2=state; s2.maxEvaluations=B2; s2.initialPopulation=X; s2.initialBest=B1best;
[B2best,T2,i2]=CMAES_CEC(f,s2,[],N,seed+777777);
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
T=[min(T1(:),Best.Cost);min(T2(:),Best.Cost)]; T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='LS-CMA'; info.Evaluations=budget; info.Rounds=i1.Rounds+i2.Rounds; info.LSFE=B1; info.CMAFE=B2; info.LSBest=B1best.Cost; info.CMABest=B2best.Cost; info.LSPopSize=size(X,1); info.LSInfo=i1; info.CMAInfo=i2;
end
