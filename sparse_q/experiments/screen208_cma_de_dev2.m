function out=screen208_cma_de_dev2(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4135:4136; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_de_dev2'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-DE-always','C-DE-adapt','D-DE-conservative'};
b=struct('cmaMixMode','always','cmaMixFraction',0.25,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
c=struct('cmaMixMode','trigger','cmaMixFraction',0.25,'cmaStagWindow',10,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
d=struct('cmaMixMode','trigger','cmaMixFraction',0.10,'cmaStagWindow',20,'cmaMixScale',0.20,'cmaMixStepCap',0.5,'cmaMixMinProgress',0.10,'cmaMixMaxProgress',0.75);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
