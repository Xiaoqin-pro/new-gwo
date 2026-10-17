function out=screen13b_recent_baselines(seeds,maxFE,D)
%SCREEN13B  screen13 的 20 种子扩展（3011:3030），与 screen13（3001:3010）
%   合并后得到 29 函数 × 30 种子的近年基线对比表。
if nargin<1 || isempty(seeds), seeds=3011:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
algs={'SGWO','DMSGWO','RLGWO','IGWO','GWO'};
labels={'S-star','DMSGWO-port','RLGWO-port','IGWO','GWO'};
states=cell(1,5); states{1}=base;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('recent2',algs,funcs,seeds,D,maxFE,opt);
end
