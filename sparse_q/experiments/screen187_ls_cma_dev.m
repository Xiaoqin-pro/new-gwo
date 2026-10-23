function out=screen187_ls_cma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4001:4002; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='ls_cma_dev'; end
a=struct('lsFrac',0.50); b=struct('lsFrac',0.70);
algs={'LSHADE','CMAES','LS_CMA','LS_CMA'}; labels={'A-LSHADE','B-CMA','C-LS50-CMA50','D-LS70-CMA30'};
opt=struct('states',{ {struct(),struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
