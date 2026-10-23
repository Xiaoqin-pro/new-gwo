function out=screen185_mm_cma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3995:3996; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='mm_cma_dev'; end
algs={'CMAES','MM_CMA','MM_CMA'}; labels={'A-CMA','B-MM70','C-MM80'};
a=struct('mmShares',[0.70 0.15 0.15]); b=struct('mmShares',[0.80 0.10 0.10]);
opt=struct('states',{ {struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
