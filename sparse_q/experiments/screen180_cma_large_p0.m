function out=screen180_cma_large_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3982:3986; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_large_p0'; end
algs={'CMAES','CMAES'}; labels={'A-CMA50','B-CMA100'};
a=struct('cmaLambda',100);
opt=struct('states',{ {struct(),a} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
