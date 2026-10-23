function out=screen201_ocma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4093:4094; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='ocma_dev'; end
algs={'CMAES','CMAES','CMAES'}; labels={'A-CMA','B-OCMA','C-OMCMA'};
a=struct('cmaOrthogonal',true); b=struct('cmaOrthogonal',true,'cmaMirror',true);
opt=struct('states',{ {struct(),a,b} },'labels',{labels}); out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
