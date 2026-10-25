function out=screen294_svadgwo_ablation30(seeds,maxFE,D,funcs,tag)
%SCREEN294_SVADGWO_ABLATION30  SVAD-GWO 消融（29 函数 x 30 种子）。
%   种子默认 3001:3030，与九臂主表一致 -> 消融臂可与主表逐 run 配对。
%   臂：
%     A-SVADGWO  完整算法（= SVADGWO.m，经 test_svad_ablate_equiv 逐位验证）
%     B-NoDiff   差分槽位替换为 alpha 中心壳（移除 DiffA）
%     C-NoE      档案槽位替换为标准 GWO 移动（移除 VMA）
%     D-NoSteer  关闭等长方向扰动
%     E-GWOonly  纯稀疏 GWO（无差分、无档案、无扰动）
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svadgwo_ablation30'; end
v={'full','nodiff','noe','nosteer','gwo'};
labels={'A-SVADGWO','B-NoDiff','C-NoE','D-NoSteer','E-GWOonly'};
algs=repmat({'SVADGWO_AB'},1,numel(v));
st=cell(1,numel(v));
for k=1:numel(v), st{k}=struct('ablationVariant',v{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
