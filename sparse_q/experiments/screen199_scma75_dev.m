function out=screen199_scma75_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4089:4090; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='scma75_dev'; end
algs={'CMAES','SCMA'}; labels={'A-CMA','B-SCMA75'};
a=struct('scmaLambda',100,'scmaK',75); opt=struct('states',{ {struct(),a} },'labels',{labels}); out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
