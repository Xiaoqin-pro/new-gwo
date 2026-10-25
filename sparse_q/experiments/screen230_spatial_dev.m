function out=screen230_spatial_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4187:4188; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='spatial_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
b=base; b.screenPolicy='spatial'; b.spatialConvFrac=0.5;
c=base; c.screenPolicy='spatial'; c.spatialConvFrac=0.7;
d=base; d.screenPolicy='spatial'; d.spatialConvFrac=1.0;
e=base; e.screenPolicy='spatial'; e.spatialConvFrac=0.0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-RandomScreen','B-Spatial5-5','C-Spatial7-3','D-Convergence10','E-Diversity10'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
