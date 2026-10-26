function out=screen300_uniform_smoke(seeds,maxFE,D,funcs,tag)
%SCREEN300_UNIFORM_SMOKE  统一填充（GWO 替 Alpha 壳）烟测：8 函数 x 2 新种子。
if nargin<1 || isempty(seeds), seeds=4631:4632; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 11 14 18 19]; end
if nargin<5 || isempty(tag), tag='uniform_smoke'; end
arms={'baseg','eonlyg'};
labels={'B-BaseG','C-EonlyG'};
st=cell(1,numel(arms));
for k=1:numel(arms), st{k}=struct('ablationVariant',arms{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO_AB2'},1,numel(arms)),funcs(:),seeds(:),D,maxFE,opt);
end
