function out=screen10_enhance(seeds,maxFE,D)
%SCREEN10  Phase-4 增强轮（docs/08）：停滞半径放大 / 成功方向引导 / G2 坐标稀疏扰动。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
b3=base; b3.stagnBoost=3;
s25=base; s25.succSteer=0.25;
s50=base; s50.succSteer=0.5;
g20=base; g20.g2Subset=0.2;
both=base; both.stagnBoost=3; both.succSteer=0.25;
algs=repmat({'SGWO'},1,6);
labels={'P4-ref','P4-boost3','P4-steer25','P4-steer50','P4-subset20','P4-both'};
states=cell(1,6); states{1}=base; states{2}=b3; states{3}=s25; states{4}=s50; states{5}=g20; states{6}=both;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq10',algs,funcs,seeds,D,maxFE,opt);
end
