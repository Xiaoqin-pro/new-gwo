function make_uav_routes()
%MAKE_UAV_ROUTES  为五张地图绘制 VAST-GWO 最优可行解的 3D 配送航迹图。
%   选取规则（固定）：正式档 raw_runs.csv 中 VAST-GWO 在每张地图上 Cost 最小的可行运行；
%   加载该运行的完整存档（Best/model/stateUAV），调用 PlotSolution 输出到 figures/。
here=fileparts(mfilename('fullpath')); sq=fileparts(here); cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'));
outRoot=fullfile(sq,'results','uav_formal_N50_30k');
figdir=fullfile(outRoot,'figures'); if ~exist(figdir,'dir'), mkdir(figdir); end
T=readtable(fullfile(outRoot,'raw_runs.csv'));
T=T(strcmp(T.Algorithm,'VAST-GWO') & T.Feasible==1,:);
maps=unique(T.Terrain,'stable');
for k=1:numel(maps)
    m=char(maps{k});
    sub=T(strcmp(T.Terrain,m),:);
    [~,i]=min(sub.Cost);
    r=sub.Run(i);
    f=fullfile(outRoot,'runs',m,sprintf('VAST-GWO_r%03d.mat',r));
    assert(isfile(f),'missing run file %s',f);
    S=load(f,'Best','model','stateUAV');
    [~,dt]=Fitness(S.Best.Vector,S.model,S.stateUAV);   % PlotSolution 需要 Best.Detail
    S.Best.Detail=dt;
    S.Best.Algorithm='VAST-GWO';
    png=fullfile(figdir,sprintf('route_%s.png',m));
    PlotSolution(S.Best,S.model,S.stateUAV,png);
    fprintf('%-9s seed=%d cost=%.2f -> %s\n',m,r,sub.Cost(i),png);
end
end
