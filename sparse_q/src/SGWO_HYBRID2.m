function [Best,T,info]=SGWO_HYBRID2(f,state,~,N,seed)
%SGWO_HYBRID2  L-SHADE global phase followed by G1+E+STEER refinement.
if ~isfield(state,'hybFrac') || isempty(state.hybFrac), state.hybFrac=0.50; end
budget=state.maxEvaluations; B1=round(state.hybFrac*budget); B2=budget-B1;
assert(B1>=N && B2>=N,'Both hybrid phases need at least N evaluations.');
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=LSHADE_CEC(f,s1,[],N,seed);
s2=state; s2.maxEvaluations=B2; P2=i1.FinalPopulation;
if size(P2,1)<N
    P2=[P2; state.initialPopulation(1:N-size(P2,1),:)];
end
s2.initialPopulation=P2;
[B2best,T2,i2]=SGWO_STEER3(f,s2,[],N,seed+777777);
T=[T1(:);T2(:)]; if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
info=struct('Evaluations',budget,'Rounds',i1.Rounds+i2.Rounds,'Algorithm','SGWO-HYBRID2', ...
    'Stage1FE',B1,'Stage2FE',B2,'Stage1Best',B1best.Cost,'Stage2Best',B2best.Cost, ...
    'Stage2PopulationSize',numel(i2.FinalFitness));
end
