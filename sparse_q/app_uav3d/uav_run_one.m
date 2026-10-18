function record = uav_run_one(algoName,mapID,repeat,outDir,pop,maxEval,seedBase,searchSeedOffset)
%UAV_RUN_ONE  单个 (算法 x 地图 x 重复) 的 3D 无人机路径规划运行。
%   协议与 9.29 benchmark-v1 一致：同一 (地图,重复) 的初始种群对所有算法相同；
%   初始化评价计入预算；搜索结束后复算一次（单独记录，不计入预算）。
%   我们的算法经适配器接入：f = @(x) Fitness(x,model,uavState)（位置空间 [0,1]^D）。
if nargin<8 || isempty(searchSeedOffset), searchSeedOffset=100000; end
if nargin<7 || isempty(seedBase), seedBase=20271004; end
cfg=uav_cfg(mapID);
model=CreateModel(cfg);
stateUAV.time=0; stateUAV.position=model.depot; stateUAV.activeIDs=model.activeIDs;
stateUAV.maxEvaluations=maxEval;
D=model.nOrders+3*(model.nOrders+1)*model.nControlPoints;
seed=seedBase+100*ceil(1/2)+repeat;     % 与 legacy 协议一致（单一 N20 情形）
initSeed=seed; searchSeed=initSeed+searchSeedOffset;
rng(initSeed); initPop=rand(pop,D);
% ---- 可行性跟踪的适应度包装（handle 类，parfor 安全） ----
trk=uav_fitness_tracker(model,stateUAV,maxEval,pop);
fitwrap=@(x) trk.eval(x);
algState=struct('initialPopulation',initPop,'lowerBound',zeros(1,D), ...
    'upperBound',ones(1,D),'maxEvaluations',maxEval);
% 显式冻结配置：VAST-GWO = N=50, G1/G2/E = 50/12/38, K=10（与 CEC 主表逐参数一致）
% VAST-A0 = 应用层机制臂：G2/E 关闭（GWO-only 稀疏池），用于检验档案机制贡献。
switch upper(algoName)
    case 'VAST-GWO'
        algFcn=@SGWO; algState.mode='sparse'; algState.K=10;
        algState.nG2=12; algState.nE=38; algState.screenPolicy='random';
    case 'VAST-A0'
        algFcn=@SGWO_ABLATION; algState.mode='sparse'; algState.K=10;
        algState.ablateG2=1; algState.ablateE=1; algState.screenPolicy='random';
    case 'VAST-N60'
        algFcn=@SGWO; algState.mode='sparse'; algState.K=10;
        algState.nG2=14; algState.nE=46; algState.screenPolicy='random';
    case 'GWO',    algFcn=@GWO;
    case 'IGWO',   algFcn=@IGWO;
    case 'PSO',    algFcn=@PSO_CEC;
    case 'CLPSO',  algFcn=@CLPSO_CEC;
    case 'HAGWO',  algFcn=@HAGWO_CEC;
    case 'AOGWO',  algFcn=@AOGWO_CEC;
    otherwise, error('unknown algorithm: %s',algoName);
end
t0=tic; [Best,T,info]=feval(algFcn,fitwrap,algState,[],pop,searchSeed); secs=toc(t0);
assert(info.Evaluations==maxEval,sprintf('FE mismatch: %d vs %d',info.Evaluations,maxEval));
assert(trk.feCount==maxEval,sprintf('tracker FE mismatch: %d vs %d',trk.feCount,maxEval));
assert(numel(T)==maxEval,'trace length mismatch');
[costV,detailV]=Fitness(Best.Vector,model,stateUAV);   % 复算（不计入预算）
assert(abs(costV-Best.Cost)<=1e-7*max(1,abs(Best.Cost)),'verification cost mismatch');
record=struct('Terrain',model.terrainName,'Scenario','N20','Stations',model.nOrders, ...
    'ControlPoints',model.nControlPoints,'Algorithm',algoName,'Run',repeat, ...
    'Seed',seed,'InitSeed',initSeed,'SearchSeed',searchSeed,'Evaluations',info.Evaluations, ...
    'Cost',Best.Cost,'InitialCost',min(trk.initCosts),'InitialFeasible',any(trk.initFeas), ...
    'Feasible',detailV.feasible,'FirstFeasibleEvaluation',trk.firstFeasible, ...
    'CandidateFeasibleRate',mean(trk.feasTrace),'Distance',detailV.distance, ...
    'Waiting',detailV.totalWaiting,'Late',detailV.totalLate,'ReturnTime',detailV.finishTime, ...
    'DepotLate',detailV.depotLate,'MinClearance',detailV.minClearance, ...
    'MaxClimbAngle',detailV.maxClimbAngle,'MaxTurnAngle',detailV.maxTurnAngle, ...
    'TerrainViolation',detailV.terrainViolation,'ObstacleViolation',detailV.obstacleViolation, ...
    'AngleViolation',detailV.totalAngleViolation,'MapViolation',detailV.mapViolation, ...
    'AltitudeViolation',detailV.altitudeViolation,'Smoothness',detailV.totalSmoothness, ...
    'SearchSeconds',secs,'VerificationEvaluations',1, ...
    'BestCost',Best.Cost,'BestVector',Best.Vector);
idx=unique(round(logspace(0,log10(maxEval),500))); idx=idx(idx>=1 & idx<=maxEval);
record.TraceFE=idx; record.Trace=T(idx);   % 轻量轨迹（500 点）随记录返回
if nargin>=4 && ~isempty(outDir)
    rel=fullfile('runs',model.terrainName,sprintf('%s_r%03d.mat',algoName,repeat));
    f=fullfile(outDir,rel); folder=fileparts(f);
    if ~exist(folder,'dir'), mkdir(folder); end
    tmp=[f '.tmp'];
    save(tmp,'Best','T','info','record','model','stateUAV','cfg','initPop');
    movefile(tmp,f,'f');
    record.File=rel;
end
end
