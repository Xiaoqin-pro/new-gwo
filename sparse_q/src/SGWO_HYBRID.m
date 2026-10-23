function [Best,T,info]=SGWO_HYBRID(f,state,~,N,seed)
%SGWO_HYBRID  G1+E+STEER exploration followed by resumable L-SHADE refinement.
if ~isfield(state,'hybFrac') || isempty(state.hybFrac), state.hybFrac=0.50; end
if isfield(state,'hybMode') && strcmpi(state.hybMode,'off')
    [Best,T,info]=SGWO_STEER3(f,state,[],N,seed); return;
end
budget=state.maxEvaluations; B1=round(state.hybFrac*budget); B2=budget-B1;
assert(B2>=N,'Hybrid second-stage budget is too small.');
s1=state; s1.maxEvaluations=B1; [B1best,T1,i1]=SGWO_STEER3(f,s1,[],N,seed);
s2=state; s2.maxEvaluations=B2; s2.initialPopulation=i1.FinalPopulation; s2.initialFitness=i1.FinalFitness;
s2.initialBest=B1best; s2.initialArchive=i1.FinalArchive;
[B2best,T2,i2]=LSHADE_RESUME(f,s2,[],N,seed+777777);
T=[T1(:);T2(:)]; if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
if B2best.Cost<B1best.Cost, Best=B2best; else, Best=B1best; end
info=struct('Evaluations',budget,'Rounds',i1.Rounds+i2.Rounds,'Algorithm','SGWO-HYBRID', ...
    'Stage1FE',B1,'Stage2FE',B2,'Stage1Best',B1best.Cost,'Stage2Best',B2best.Cost, ...
    'Stage2StartBest',i2.InitialCost,'Stage2PopulationSize',i2.FinalPopulationSize);
end
