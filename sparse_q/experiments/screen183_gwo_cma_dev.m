function out=screen183_gwo_cma_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3991:3992; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='gwo_cma_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
a=common; a.gwoFrac=0.30; b=common; b.gwoFrac=0.50;
algs={'SGWO_STEER3','CMAES','GWO_CMA','GWO_CMA'}; labels={'A-G1E','B-CMA','C-G1E-CMA30','D-G1E-CMA50'};
opt=struct('states',{ {common,struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
