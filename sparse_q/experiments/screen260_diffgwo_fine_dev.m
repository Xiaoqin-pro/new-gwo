function out=screen260_diffgwo_fine_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4303:4304; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffgwo_fine_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','hybrid','opFixed',1,'opDiffMode','nowarc','opF',0.5,'opShare',0.6);
a=base; a.opPolicy='fixed'; a.opFixed=1; a.opShare=0;
b=base; b.opShare=0.6;
c=base; c.opShare=0.7;
d=base; d.opShare=0.8;
e=base; e.opPolicy='fixed'; e.opFixed=2; e.opShare=0; e.opF=0.45;
f=base; f.opPolicy='fixed'; f.opFixed=2; f.opShare=0; f.opF=0.55;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-Mix60','C-Mix70','D-Mix80','E-F045','F-F055'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
