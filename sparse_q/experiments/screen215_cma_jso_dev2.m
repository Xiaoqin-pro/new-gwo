function out=screen215_cma_jso_dev2(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4152:4153; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_jso_dev2'; end
algs={'CMAES','CMA_JSO','CMA_LS','CMA_JSO','jSO'};
labels={'A-CMA','B-CMAJSO80','C-CMA-LS80','D-CMAJSO80-RandomStart','E-jSO'};
b=struct('cmaJsoFraction',0.80,'cmaJsoMix',0.20);
c=struct('cmaFraction',0.80,'cmaLsMix',0.20);
d=struct('cmaJsoFraction',0.80,'cmaJsoMix',1.0);
opt=struct('states',{ {struct(),b,c,d,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
