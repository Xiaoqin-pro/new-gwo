function out=screen162_cma2_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3882:3883; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cma2_dev'; end
algs={'CMAES','CMA2'}; labels={'A-CMA','B-CMA2'};
opt=struct('states',{ {struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
