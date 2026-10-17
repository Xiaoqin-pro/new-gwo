function out=screen14_combo_v2(seeds,maxFE,D)
%SCREEN14  v2 组合测试（fresh 种子 3031:3060）：
%   steer50（成功方向引导 50%，误差轴）× subset20（G2 坐标稀疏扰动，停滞轴）。
%   与既有 freshv2 的 V1/steer50/subset20 行同种子配对比较。
if nargin<1 || isempty(seeds), seeds=3031:3060; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
combo=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'succSteer',0.5,'g2Subset',0.2);
algs={'SGWO'}; labels={'V2-steer50-g20'};
states=cell(1,1); states{1}=combo;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('combo2',algs,funcs,seeds,D,maxFE,opt);
end
