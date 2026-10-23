function out=screen177_mnc80_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3976:3977; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='mnc80_dev'; end
algs={'CMAES','MNC_CMA'}; labels={'A-CMA','B-MNC80'};
a=struct('mncMode','fixed','mncK',3,'mncShares',[0.80 0.10 0.10]);
opt=struct('states',{ {struct(),a} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
