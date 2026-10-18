function res = uav_runner(job)
%UAV_RUNNER  runBatch4 的工作函数：单次 (算法x地图x重复) 运行。
persistent ready
if isempty(ready)
    here=fileparts(mfilename('fullpath')); sq=fileparts(here);
    cfg=newgwo_config();
    addpath(here,fullfile(sq,'src'),fullfile(cfg.root,'src'),fullfile(cfg.wolfDir,'src'));
    ready=true;
end
res=uav_run_one(job.algorithm,job.mapID,job.repeat,job.outDir,job.pop, ...
    job.maxFE,job.seedBase,job.searchSeedOffset);
end
