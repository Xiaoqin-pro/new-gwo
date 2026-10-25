function out=screen207_cma_de_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4133:4134; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_de_dev'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-DE-always','C-DE-trigger','D-random-always'};
states={struct(),struct('cmaMixMode','always'),struct('cmaMixMode','trigger'),struct('cmaMixMode','random')};
opt=struct('states',{states},'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
