function out=screen200_mirror_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4091:4092; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='mirror_cma_dev'; end
algs={'CMAES','CMAES'}; labels={'A-CMA','B-MirrorCMA'}; a=struct('cmaMirror',true); opt=struct('states',{ {struct(),a} },'labels',{labels}); out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
