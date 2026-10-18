function smoke_uav()
%SMOKE_UAV  应用移植烟测：建模 / 适应度 / 七算法适配器 / 速度实测。
here=fileparts(mfilename('fullpath')); sq=fileparts(here);
cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'),fullfile(cfg0.wolfDir,'src'));
fprintf('== smoke_uav ==\n');
cfg=uav_cfg(1); model=CreateModel(cfg);
D=model.nOrders+3*(model.nOrders+1)*model.nControlPoints;
fprintf('terrain=%s orders=%d D=%d obstacles=%d\n',model.terrainName,model.nOrders,D,numel(model.obstacles));
st.time=0; st.position=model.depot; st.activeIDs=model.activeIDs; st.maxEvaluations=3000;
rng(20271105); x=rand(1,D); [c,dt]=Fitness(x,model,st);
fprintf('random point: cost=%.3f feasible=%d distance=%.3f\n',c,dt.feasible,dt.distance);
algs={'VAST-GWO','GWO','IGWO','PSO','CLPSO','HAGWO','AOGWO'};
for i=1:numel(algs)
    t0=tic; rec=uav_run_one(algs{i},1,777,'',60,3000); s=toc(t0);
    ff=rec.FirstFeasibleEvaluation;
    if isnan(ff), ffStr='--'; else, ffStr=num2str(ff); end
    fprintf('  %-9s 3000FE %7.1fs  cost=%12.3f  feasible=%d  firstFeas=%s  evals=%d\n', ...
        algs{i},s,rec.Cost,rec.Feasible,ffStr,rec.Evaluations);
end
fprintf('== smoke_uav PASS ==\n');
end
