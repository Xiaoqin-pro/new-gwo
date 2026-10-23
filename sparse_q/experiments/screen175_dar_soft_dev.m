function out=screen175_dar_soft_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3896:3897; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='dar_soft_dev'; end
algs={'CMAES','DAR_CMA','DAR_CMA'}; labels={'A-CMA','B-DAR-Hard','C-DAR-Soft'};
a=struct('darSoft',false); b=struct('darSoft',true);
opt=struct('states',{ {struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
