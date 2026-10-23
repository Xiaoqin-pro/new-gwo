function out=screen155_pilot_scale2_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3874:3875; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='pilot_scale2_dev'; end
algs={'LSHADE','CMAES','PILOT','PILOT'}; labels={'A-LSHADE','B-CMAES','C-PilotScale1','D-PilotScale2'};
a=struct('pilotFrac',0.20,'pilotRule','scale'); b=struct('pilotFrac',0.20,'pilotRule','scale2');
opt=struct('states',{ {struct(),struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
