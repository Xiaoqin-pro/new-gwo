function out=screen207_cne_full_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4161:4162; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cne_full_dev_b'; end
algs={'LSHADE','jSO','LSHADE_CNEPSIN','CMAES'};
labels={'A-LSHADE','B-jSO','C-CNEPSIN','D-CMA'};
opt=struct('states',{ {struct(),struct(),struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
