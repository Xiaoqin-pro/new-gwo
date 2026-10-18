function out=screen22_clpso(seeds,maxFE,D)
%SCREEN22  CLPSO 严格复现（TEC2006 原版代码包）新增臂批：替换归档 CLPSO。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
algs={'CLPSO'};
labels={'CLPSO(2006)'};
states=cell(1,1);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('clpso',algs,funcs,seeds,D,maxFE,opt);
end
