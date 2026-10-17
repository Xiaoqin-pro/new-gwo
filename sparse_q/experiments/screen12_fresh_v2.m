function out=screen12_fresh_v2(seeds,maxFE,D)
%SCREEN12  新种子（3031:3060）D=50 对拍（6 臂 + IGWO 同批重跑）：
%   V1 冻结 / steer25 / steer50 / subset20 / K5 / IGWO(只读基线)。
%   目标：改善对 IGWO 的 Holm 显著计数（当前正式批 3001:3030 为 +12/-6）。
if nargin<1 || isempty(seeds), seeds=3031:3060; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
s25=base; s25.succSteer=0.25;
s50=base; s50.succSteer=0.5;
g20=base; g20.g2Subset=0.2;
k5=base; k5.K=5;
algs={'SGWO','SGWO','SGWO','SGWO','SGWO','IGWO'};
labels={'V1-frozen','V2-steer25','V2-steer50','V2-subset20','V2-K5','IGWO-fresh'};
states=cell(1,6); states{1}=base; states{2}=s25; states{3}=s50; states{4}=g20; states{5}=k5; states{6}=struct();
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('freshv2',algs,funcs,seeds,D,maxFE,opt);
end
