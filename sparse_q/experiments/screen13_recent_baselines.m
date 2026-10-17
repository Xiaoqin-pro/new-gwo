function out=screen13_recent_baselines(seeds,maxFE,D)
%SCREEN13  近年 GWO 强基线复现对比批（docs/11）：
%   S-star(v1 冻结) / DMSGWO(论文公式补全) / RLGWO(作者 Python 移植) /
%   IGWO(审计) / GWO(审计)，同 init 池、同种子、同 100k 真 FE。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
algs={'SGWO','DMSGWO','RLGWO','IGWO','GWO'};
labels={'S-star','DMSGWO-port','RLGWO-port','IGWO','GWO'};
states=cell(1,5); states{1}=base;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('recent',algs,funcs,seeds,D,maxFE,opt);
end
