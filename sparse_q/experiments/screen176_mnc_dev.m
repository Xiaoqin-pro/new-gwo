function out=screen176_mnc_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3974:3975; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='mnc_dev'; end
algs={'CMAES','MNC_CMA','MNC_CMA'}; labels={'A-CMA','B-MNC-Fixed','C-MNC-Adaptive'};
a=struct('mncMode','fixed','mncK',3); b=a; b.mncMode='adaptive';
opt=struct('states',{ {struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
