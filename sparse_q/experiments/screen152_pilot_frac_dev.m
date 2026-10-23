function out=screen152_pilot_frac_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3867:3868; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='pilot_frac_dev'; end
algs={'LSHADE','CMAES','PILOT','PILOT'}; labels={'A-LSHADE','B-CMAES','C-Pilot10','D-Pilot20'};
a10=struct('pilotFrac',0.10); a20=struct('pilotFrac',0.20);
opt=struct('states',{ {struct(),struct(),a10,a20} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
