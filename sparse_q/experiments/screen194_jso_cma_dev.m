function out=screen194_jso_cma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4030:4031; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='jso_cma_dev'; end
a=struct('jsoFrac',0.50); b=struct('jsoFrac',0.70);
algs={'CMAES','jSO','JSO_CMA','JSO_CMA'}; labels={'A-CMA','B-jSO','C-JSO50-CMA50','D-JSO70-CMA30'};
opt=struct('states',{ {struct(),struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
