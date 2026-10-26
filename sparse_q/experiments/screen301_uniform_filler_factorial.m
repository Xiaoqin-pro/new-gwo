function out=screen301_uniform_filler_factorial(seeds,maxFE,D,funcs,tag)
%SCREEN301_UNIFORM_FILLER_FACTORIAL  2x2 主消融的统一填充版（29 函数 x 30 种子）。
%   只跑两个新臂；Diff-only 与 Full 不变（E 关闭时 38 槽本来就是 GWO 填充）。
%     B-BaseG  : 12 槽 GWO + 38 槽 GWO，无档案，无差分
%     C-EonlyG : 12 槽 GWO + 38 槽 E，有档案，无差分
%   与 screen299 的 base/eonly 唯一差别：12 个差分预算槽位由 Alpha 壳改为普通 GWO，
%   使"关闭 DiffA"等于"用普通 GWO 替代 DiffA"，四角填充策略对称。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='uniform_filler_factorial'; end
arms={'baseg','eonlyg'};
labels={'B-BaseG','C-EonlyG'};
st=cell(1,numel(arms));
for k=1:numel(arms), st{k}=struct('ablationVariant',arms{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO_AB2'},1,numel(arms)),funcs(:),seeds(:),D,maxFE,opt);
end
