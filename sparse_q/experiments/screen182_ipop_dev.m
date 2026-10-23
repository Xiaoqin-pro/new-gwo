function out=screen182_ipop_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3989:3990; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='ipop_cma_dev'; end
algs={'CMAES','CMAES','IPOP_CMA'}; labels={'A-CMA50','B-CMA100','C-IPOP'};
a=struct('cmaLambda',100); opt=struct('states',{ {struct(),a,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
