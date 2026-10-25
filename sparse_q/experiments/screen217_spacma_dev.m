function out=screen217_spacma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4156:4157; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='spacma_dev'; end
algs={'CMAES','SPACMA','SPACMA','SPACMA','jSO'};
labels={'A-CMA','B-SPACMA-adaptive','C-SPACMA-fixed','D-SPACMA-random','E-jSO'};
b=struct('spaClassMode','adaptive');
c=struct('spaClassMode','fixed');
d=struct('spaClassMode','random');
opt=struct('states',{ {struct(),b,c,d,struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
