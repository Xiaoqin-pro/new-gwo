function out=screen21_pso(seeds,maxFE,D)
%SCREEN21  经典 PSO（惯性权重版）新增臂批：替换 SPSO-2011（用户决定）。
%  复用 seeds 3001:3030 上其余既有臂。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
algs={'PSO'};
labels={'PSO(classic)'};
states=cell(1,1);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('pso',algs,funcs,seeds,D,maxFE,opt);
end
