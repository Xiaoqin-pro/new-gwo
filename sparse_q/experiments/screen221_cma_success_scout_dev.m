function out=screen221_cma_success_scout_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4164:4165; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_success_scout_dev'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-Random5','C-SuccessRandom5','D-SuccessHalton5'};
b=struct('cmaMixMode','random','cmaMixFraction',0.05);
c=struct('cmaMixMode','random_success','cmaMixFraction',0.05,'cmaScoutSuccessThreshold',0.20);
d=struct('cmaMixMode','halton_success','cmaMixFraction',0.05,'cmaScoutSuccessThreshold',0.20);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
