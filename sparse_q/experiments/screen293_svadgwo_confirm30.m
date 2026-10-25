function out=screen293_svadgwo_confirm30(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svadgwo_confirm30'; end
algs={'SVADGWO'};
labels={'SVAD-GWO'};
opt=struct('states',{ {struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
