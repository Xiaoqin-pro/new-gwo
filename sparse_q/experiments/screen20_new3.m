function out=screen20_new3(seeds,maxFE,D)
%SCREEN20  三个新增 GWO 基线批（HAGWO / AOGWO / EDGWO）；
%  复用 seeds 3001:3030 上既有的 GWO/IGWO/PSO/CLPSO/VAST-GWO 结果。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
algs={'HAGWO','AOGWO','EDGWO'};
labels={'HAGWO','AOGWO','EDGWO'};
states=cell(1,3);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('new3',algs,funcs,seeds,D,maxFE,opt);
end
