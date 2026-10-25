function out=screen216_cma_gated_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4154:4155; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_gated_dev'; end
algs={'CMAES','CMA_JSO','CMA_GATED','CMA_GATED'};
labels={'A-CMA','B-FixedHandoff','C-Gated1e-4','D-Gated1e-6'};
b=struct('cmaJsoFraction',0.80,'cmaJsoMix',0.20);
c=struct('cmaGateFraction',0.80,'cmaGateMix',0.20,'cmaGateTol',1e-4,'cmaGateWindow',10000);
d=struct('cmaGateFraction',0.80,'cmaGateMix',0.20,'cmaGateTol',1e-6,'cmaGateWindow',10000);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
