function out=screen205_lshade_cml_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4114:4118; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='lshade_cml_p0'; end
algs={'LSHADE','jSO','LSHADE_CML','CMAES'}; labels={'A-LSHADE','B-jSO','C-CML','D-CMA'};
opt=struct('states',{ {struct(),struct(),struct(),struct()} },'labels',{labels}); out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
