function out=screen237_diffhybrid20_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4212:4213; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='diffhybrid20_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','fixed','opFixed',1);
b=base; b.opFixed=2;
c=base; c.opPolicy='hybrid'; c.opShare=0.5;
d=base; d.opPolicy='early'; d.opPhaseFrac=0.5;
e=base; e.opPolicy='late'; e.opPhaseFrac=0.5;
f=base; f.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-DiffAll','C-DiffHalf','D-DiffEarly','E-DiffLate','F-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
