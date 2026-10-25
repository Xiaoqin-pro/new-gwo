function out=screen220_cma_halton_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4162:4163; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma_halton_dev'; end
algs={'CMAES','CMA_DE','CMA_DE','CMA_DE'};
labels={'A-CMA','B-Random5','C-Halton5','D-Halton10'};
b=struct('cmaMixMode','random','cmaMixFraction',0.05);
c=struct('cmaMixMode','halton','cmaMixFraction',0.05);
d=struct('cmaMixMode','halton','cmaMixFraction',0.10);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
