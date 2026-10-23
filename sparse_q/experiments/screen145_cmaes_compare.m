function out=screen145_cmaes_compare(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3860:3861; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cmaes_compare'; end
algs={'LSHADE','CMAES'}; labels={'A-LSHADE','B-CMAES'};
opt=struct('states',{ {struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
