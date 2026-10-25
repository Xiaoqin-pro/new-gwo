function out=screen219_spacma_gate_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4160:4161; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='spacma_gate_dev'; end
algs={'CMAES','SPACMA200','SPACMA200','SPACMA200'};
labels={'A-CMA50','B-SPACMA200','C-Gate0.10','D-Gate0.20'};
b=struct('spaClassMode','adaptive');
c=struct('spaClassMode','adaptive','spaProgressBias',0.10,'spaProgressWindow',5000,'spaProgressTol',1e-4);
d=struct('spaClassMode','adaptive','spaProgressBias',0.20,'spaProgressWindow',5000,'spaProgressTol',1e-4);
opt=struct('states',{ {struct(),b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
