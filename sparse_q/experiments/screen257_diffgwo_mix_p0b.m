function out=screen257_diffgwo_mix_p0b(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4286:4290; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='diffgwo_mix_p0b'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','hybrid','opFixed',1,'opDiffMode','nowarc','opF',0.5,'opShare',0);
a=base; a.opPolicy='fixed'; a.opFixed=1;
b=base; b.opShare=0.25;
c=base; c.opShare=0.50;
d=base; d.opShare=0.75;
e=base; e.opShare=1.0; e.opPolicy='fixed'; e.opFixed=2;
f=base; f.opShare=0; f.opPolicy='fixed'; f.opFixed=1; f.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-Mix25','C-Mix50','D-Mix75','E-DiffAll','F-NoSTEER'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
