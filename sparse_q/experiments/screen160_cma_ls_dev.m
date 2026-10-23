function out=screen160_cma_ls_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3878:3879; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_ls_dev'; end
algs={'LSHADE','CMAES','CMA_LS'}; labels={'A-LSHADE','B-CMAES','C-CMA-LS80'};
arm=struct('cmaFraction',0.80);
opt=struct('states',{ {struct(),struct(),arm} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
