function out=screen218_spacma_pop_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4158:4159; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='spacma_pop_dev'; end
algs={'CMAES','SPACMA100','SPACMA200','SPACMA400'};
labels={'A-CMA50','B-SPACMA100','C-SPACMA200','D-SPACMA400'};
opt=struct('states',{ {struct(),struct(),struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
