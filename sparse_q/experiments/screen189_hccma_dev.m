function out=screen189_hccma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4007:4008; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='hccma_dev'; end
algs={'CMAES','HCCMA','HCCMA'}; labels={'A-CMA','B-HCCMA70','C-HCCMA50'};
a=struct('hcShareF',0.70); b=struct('hcShareF',0.50);
opt=struct('states',{ {struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
