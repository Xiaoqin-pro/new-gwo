function out=screen161_cma_ls_mix_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3880:3881; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_ls_mix_dev'; end
algs={'CMAES','CMA_LS','CMA_LS','CMA_LS'}; labels={'A-CMA','B-Mix0','C-Mix50','D-Mix100'};
a=struct('cmaFraction',0.80,'cmaLsMix',0.0); b=a; b.cmaLsMix=0.50; c=a; c.cmaLsMix=1.0;
opt=struct('states',{ {struct(),a,b,c} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
