function out=screen172_adapt_core_p1(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3964:3973; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='adapt_core_p1'; end
algs={'LSHADE','CMAES','ADAPT_CORE'}; labels={'A-LSHADE','B-CMAES','C-AdaptCore'};
opt=struct('states',{ {struct(),struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
