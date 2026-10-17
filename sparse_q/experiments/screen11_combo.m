function out=screen11_combo(seeds,maxFE,D)
%SCREEN11  组合验证（docs/09）：成功方向引导（误差轴）× 坐标稀疏扰动（停滞轴）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
s25=base; s25.succSteer=0.25;
g20=base; g20.g2Subset=0.2;
combo=s25; combo.g2Subset=0.2;
algs=repmat({'SGWO'},1,4);
labels={'P4-ref','P4-steer25','P4-subset20','P4-s25g20'};
states=cell(1,4); states{1}=base; states{2}=s25; states{3}=g20; states{4}=combo;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq11',algs,funcs,seeds,D,maxFE,opt);
end
