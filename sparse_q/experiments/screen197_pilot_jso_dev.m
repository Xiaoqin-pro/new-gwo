function out=screen197_pilot_jso_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4072:4073; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='pilot_jso_dev'; end
algs={'CMAES','jSO','PILOT_JSO'}; labels={'A-CMA','B-jSO','C-PilotJSO'};
arm=struct('pilotFrac',0.20);
opt=struct('states',{ {struct(),struct(),arm} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
