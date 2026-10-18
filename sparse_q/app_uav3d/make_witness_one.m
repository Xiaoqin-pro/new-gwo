function W = make_witness_one(mapID,N,FE,FE2)
%MAKE_WITNESS_ONE  单张地图的见证生成（GWO 基线；不可行则升预算）。
cfg=uav_cfg(mapID); model=CreateModel(cfg);
st.time=0; st.position=model.depot; st.activeIDs=model.activeIDs; st.maxEvaluations=FE;
D=model.nOrders+3*(model.nOrders+1)*model.nControlPoints;
seed=20271004+100*ceil(1/2)+mapID;
rng(seed); initPop=rand(N,D);
f=@(x) Fitness(x,model,st);
st2=st; st2.maxEvaluations=FE2; f2=@(x) Fitness(x,model,st2);
algState=struct('initialPopulation',initPop,'lowerBound',zeros(1,D), ...
    'upperBound',ones(1,D),'maxEvaluations',FE);
[Best,~,info]=GWO(f,algState,[],N,seed+100000);
assert(info.Evaluations==FE);
[c,dt]=Fitness(Best.Vector,model,st);
used=FE;
if ~dt.feasible
    algState.maxEvaluations=FE2;
    [Best,~,info]=GWO(f2,algState,[],N,seed+100000);
    assert(info.Evaluations==FE2);
    [c,dt]=Fitness(Best.Vector,model,st2);
    used=FE2;
end
W=struct('Map',model.terrainName,'MapID',mapID,'Algorithm','GWO','N',N, ...
    'Evaluations',used,'Seed',seed,'Vector',Best.Vector,'Cost',c, ...
    'Feasible',dt.feasible,'Distance',dt.distance,'Late',dt.totalLate, ...
    'Waiting',dt.totalWaiting, ...
    'Violations',dt.terrainViolation+dt.obstacleViolation+dt.totalAngleViolation+ ...
        dt.mapViolation+dt.altitudeViolation);
end
