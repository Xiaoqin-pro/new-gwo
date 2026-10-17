function out=screen9_boost(seeds,maxFE,D)
%SCREEN9  停滞触发半径放大（"跳出局部最优"，docs/08；用户允许调参后的增强轮）。
%   变体：S*-K10 参照 / boost3 / boost5（仅壳类候选半径在停滞时放大）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
b3=base; b3.stagnBoost=3;
b5=base; b5.stagnBoost=5;
algs=repmat({'SGWO'},1,3); labels={'Sstar-K10','Sstar-boost3','Sstar-boost5'};
states=cell(1,3); states{1}=base; states{2}=b3; states{3}=b5;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq9',algs,funcs,seeds,D,maxFE,opt);
end
