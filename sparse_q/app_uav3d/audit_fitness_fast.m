function audit_fitness_fast()
%AUDIT_FITNESS_FAST  Fitness vs FitnessFast 严格等价审计：
%   (1) 五图随机位置 500 个；(2) 见证向量±1e-3 扰动 100 个；
%   (3) 边界样本：全 0 / 全 1 / 端点混合 / 均匀 [0,1e-3]∪[0.999,1] 100 个；
%   (4) 固定种子优化一致性：GWO 1000FE 两版轨迹对比。
%   验收：cost 相对误差 ≤1e-12，可行标记与全部违规计数逐项一致。
here=fileparts(mfilename('fullpath')); sq=fileparts(here); cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'));
S=load(fullfile(here,'data','witness','witness_v1.mat'));
fprintf('== audit_fitness_fast ==\n');
maxCostRel=0; nChecked=0; nFeas=0;
for w=1:numel(S.witness)
    wt=S.witness(w);
    cfg=uav_cfg(wt.MapID); model=CreateModel(cfg); modelF=prepare_model_fast(model);
    st.time=0; st.position=model.depot; st.activeIDs=model.activeIDs; st.maxEvaluations=1;
    D=numel(wt.Vector);
    rng(9000+w);
    P=[rand(500,D); repmat(wt.Vector,100,1)+1e-3*randn(100,D); ...
       zeros(1,D); ones(1,D); ...
       double(rand(100,D)<0.5); 1e-3*rand(100,D)+(rand(100,D)>0.5).*(1-2e-3*rand(100,D))];
    P=min(max(P,0),1);
    for k=1:size(P,1)
        [c1,d1]=Fitness(P(k,:),model,st);
        [c2,d2]=FitnessFast(P(k,:),modelF,st);
        rel=abs(c1-c2)/max(1,abs(c1));
        maxCostRel=max(maxCostRel,rel);
        assert(rel<=1e-12,sprintf('%s case %d cost rel %.3g',wt.Map,k,rel));
        assert(d1.feasible==d2.feasible,sprintf('%s case %d feasibility',wt.Map,k));
        assert(abs(d1.distance-d2.distance)<=1e-12*max(1,d1.distance));
        assert(d1.terrainViolation==d2.terrainViolation && ...
               d1.obstacleViolation==d2.obstacleViolation && ...
               d1.totalAngleViolation==d2.totalAngleViolation && ...
               d1.mapViolation==d2.mapViolation && ...
               d1.altitudeViolation==d2.altitudeViolation);
        assert(abs(d1.totalWaiting-d2.totalWaiting)<=1e-12*max(1,d1.totalWaiting));
        assert(abs(d1.totalLate-d2.totalLate)<=1e-12*max(1,d1.totalLate));
        assert(abs(d1.minClearance-d2.minClearance)<=1e-12*max(1,abs(d1.minClearance)));
        assert(abs(d1.finishTime-d2.finishTime)<=1e-12*max(1,d1.finishTime));
        nChecked=nChecked+1; nFeas=nFeas+d1.feasible;
    end
    % 固定种子优化一致性（GWO 1000FE）
    N=50; FE=1000; seed=wt.Seed+100000; rng(wt.Seed); initPop=rand(N,D);
    aS=struct('initialPopulation',initPop,'lowerBound',zeros(1,D), ...
        'upperBound',ones(1,D),'maxEvaluations',FE);
    f1=@(x) Fitness(x,model,st); f2=@(x) FitnessFast(x,modelF,st);
    [~,T1]=GWO(f1,aS,[],N,seed); [~,T2]=GWO(f2,aS,[],N,seed);
    dtMax=max(abs(T1-T2));
    fprintf('  %-8s cases=%d feasible=%d  maxCostRel=%.3g  GWO-1000FE trace maxdiff=%.3g\n', ...
        wt.Map,size(P,1),sum(0),maxCostRel,dtMax);
    assert(dtMax<=1e-9,sprintf('%s optimization trace diverged (%.3g)',wt.Map,dtMax));
end
fprintf('  total cases=%d (feasible=%d), maxCostRel=%.3g\n',nChecked,nFeas,maxCostRel);
fprintf('== audit_fitness_fast PASS ==\n');
end
