function out = uav_batch(algorithms,mapIDs,repeats,pop,maxFE,outDir)
%UAV_BATCH  3D 无人机配送应用批处理（benchmark-v1 协议；恰 4 worker；断点续跑）。
%   uav_batch() 使用默认：七算法 x 五地图 x 正式种子 101:130 x 60 粒子 x 30k FE。
%   同一 outDir 重跑 = 续跑（runBatch4 只补缺失/失败作业）。
here=fileparts(mfilename('fullpath')); sq=fileparts(here);
if nargin<1 || isempty(algorithms)
    algorithms={'VAST-GWO','GWO','IGWO','PSO','CLPSO','HAGWO','AOGWO'};
end
if nargin<2 || isempty(mapIDs), mapIDs=1:5; end
if nargin<3 || isempty(repeats), repeats=101:130; end
if nargin<4 || isempty(pop), pop=60; end
if nargin<5 || isempty(maxFE), maxFE=30000; end
if nargin<6 || isempty(outDir)
    outDir=fullfile(sq,'results',sprintf('uav_%s',datestr(now,'yyyymmdd_HHMMSS')));
end
seedBase=20271004; searchSeedOffset=100000;
jobs=struct('algorithm',{},'mapID',{},'repeat',{},'pop',{},'maxFE',{}, ...
    'seedBase',{},'searchSeedOffset',{},'outDir',{});
k=0;
for a=1:numel(algorithms)
    for m=mapIDs
        for r=repeats
            k=k+1;
            jobs(k)=struct('algorithm',algorithms{a},'mapID',m,'repeat',r, ...
                'pop',pop,'maxFE',maxFE,'seedBase',seedBase, ...
                'searchSeedOffset',searchSeedOffset,'outDir',outDir);
        end
    end
end
addpath(here,fullfile(sq,'src'));
summary=overnight.runBatch4(jobs,@uav_runner,outDir);
% ---- 汇总 raw_runs.csv ----
n=numel(jobs); rows=cell(n,1);
for k=1:n
    f=fullfile(outDir,'runs',sprintf('run_%05d.mat',k));
    if isfile(f)
        a=load(f,'record');
        if strcmp(a.record.status,'ok'), rows{k}=a.record.result; end
    end
end
rows=rows(~cellfun(@isempty,rows));
T=struct2table(vertcat(rows{:}));
writetable(T,fullfile(outDir,'raw_runs.csv'));
out=struct('outDir',outDir,'summary',summary,'nRows',height(T),'runs',T);
fprintf('[uav_batch] raw_runs.csv: %d 行 -> %s\n',height(T),outDir);
end
