function [Best,T,info]=CMA2_CEC(f,state,~,N,seed)
%CMA2_CEC  Two independent 50/50 CMA-ES starts with a shared verified output.
budget=state.maxEvaluations; B1=floor(budget/2); B2=budget-B1;
assert(B1>=N && B2>=N);
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=CMAES_CEC(f,s1,[],N,seed+111111);
rng(seed+777777,'twister'); X2=-100+200*rand(N,size(state.initialPopulation,2));
s2=state; s2.maxEvaluations=B2; s2.initialPopulation=X2;
[B2best,T2,i2]=CMAES_CEC(f,s2,[],N,seed+777777);
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
T=[min(T1(:),Best.Cost);min(T2(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info=struct('Algorithm','CMA2','Evaluations',budget,'Rounds',i1.Rounds+i2.Rounds, ...
 'Start1FE',B1,'Start2FE',B2,'Start1Best',B1best.Cost,'Start2Best',B2best.Cost, ...
 'Start1Info',i1,'Start2Info',i2);
end
