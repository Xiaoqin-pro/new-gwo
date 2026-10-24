function out=screen258_diffgwo_f_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4291:4292; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='diffgwo_f_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','fixed','opFixed',2,'opDiffMode','nowarc','opF',0.5);
a=base; a.opPolicy='fixed'; a.opFixed=1;
b=base; b.opF=0.2;
c=base; c.opF=0.35;
d=base; d.opF=0.5;
e=base; e.opF=0.7;
f=base; f.opF=1.0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-F02','C-F035','D-F05','E-F07','F-F10'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
