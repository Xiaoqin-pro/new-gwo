function out=screen224_spacma_native_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4175:4176; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='spacma_native_dev'; end
algs={'CMAES','SPACMA200','SPACMA600','SPACMA900'};
labels={'A-CMA50','B-SPACMA200','C-SPACMA600','D-SPACMA900'};
opt=struct('states',{ {struct(),struct(),struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
