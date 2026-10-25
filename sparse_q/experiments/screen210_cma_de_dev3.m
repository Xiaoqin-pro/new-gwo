function out=screen210_cma_de_dev3(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4139:4140; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_de_dev3'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-Period5','C-Period10','D-DE5pct'};
b=struct('cmaMixMode','periodic','cmaMixPeriod',5,'cmaMixFraction',0.25,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
c=struct('cmaMixMode','periodic','cmaMixPeriod',10,'cmaMixFraction',0.35,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
d=struct('cmaMixMode','always','cmaMixFraction',0.05,'cmaMixScale',0.35,'cmaMixStepCap',1.0);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
