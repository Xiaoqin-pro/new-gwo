function out=screen195_jso_cma_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4032:4036; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='jso_cma_p0'; end
algs={'CMAES','jSO','JSO_CMA'}; labels={'A-CMA','B-jSO','C-JSO70-CMA30'};
a=struct('jsoFrac',0.70);
opt=struct('states',{ {struct(),struct(),a} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
