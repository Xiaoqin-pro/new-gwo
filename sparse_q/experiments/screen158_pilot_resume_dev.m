function out=screen158_pilot_resume_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3876:3877; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='pilot_resume_dev'; end
algs={'LSHADE','CMAES','PILOT_RESUME'}; labels={'A-LSHADE','B-CMAES','C-PilotResume20'};
arm=struct('pilotFrac',0.20,'pilotRule','scale2');
opt=struct('states',{ {struct(),struct(),arm} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
