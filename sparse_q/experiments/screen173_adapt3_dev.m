function out=screen173_adapt3_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3892:3893; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='adapt3_dev'; end
algs={'LSHADE','CMAES','ADAPT_CORE'}; labels={'A-LSHADE','B-CMAES','C-Adapt3'};
a=struct('adaptPatience',3); opt=struct('states',{ {struct(),struct(),a} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
