function out=screen213_cma_scout_dev2(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4148:4149; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_scout_dev2'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-Maximin5','C-AdaptiveMaximin','D-AdaptiveRandom'};
b=struct('cmaMixMode','maximin','cmaMixFraction',0.05);
c=struct('cmaMixMode','maximin_trigger','cmaMixBaseFraction',0.02,'cmaMixFraction',0.10,'cmaStagWindow',12,'cmaBoostLength',4);
d=struct('cmaMixMode','random_trigger','cmaMixBaseFraction',0.02,'cmaMixFraction',0.10,'cmaStagWindow',12,'cmaBoostLength',4);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
