function out=screen214_cma_jso_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4150:4151; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_jso_dev'; end
algs={'CMAES','CMA_JSO','CMA_JSO','jSO'};
labels={'A-CMA','B-CMAJSO90','C-CMAJSO80','D-jSO'};
b=struct('cmaJsoFraction',0.90,'cmaJsoMix',0.20);
c=struct('cmaJsoFraction',0.80,'cmaJsoMix',0.20);
opt=struct('states',{ {struct(),b,c,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
