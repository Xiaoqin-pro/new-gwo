function out=screen209_cma_tail_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4137:4138; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_tail_dev'; end
algs={'CMAES','CMA_TAIL','CMA_TAIL','CMA_TAIL'};
labels={'A-CMA','B-Tail-always','C-Tail-adaptive','D-Random-always'};
b=struct('cmaTailMode','always','cmaTailFraction',0.12,'cmaTailNu',5);
c=struct('cmaTailMode','trigger','cmaTailBaseFraction',0.03,'cmaTailFraction',0.18,'cmaTailStagWindow',12,'cmaTailNu',5);
d=struct('cmaTailMode','random','cmaTailFraction',0.12);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
