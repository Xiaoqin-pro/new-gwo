function out=screen261_diffgwo_p1b(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4305:4314; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffgwo_p1b'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5);
a=base;
b=base; b.opFixed=2;
c=base; c.opPolicy='hybrid'; c.opShare=0.6; c.opFixed=1;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-DiffAll','C-Mix60'};
opt=struct('states',{ {a,b,c} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
