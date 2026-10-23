function out=screen154_pilot_scale_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3872:3873; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='pilot_scale_dev'; end
algs={'LSHADE','CMAES','PILOT','PILOT'}; labels={'A-LSHADE','B-CMAES','C-PilotBest20','D-PilotScale20'};
a=struct('pilotFrac',0.20,'pilotRule','best'); b=struct('pilotFrac',0.20,'pilotRule','scale');
opt=struct('states',{ {struct(),struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
