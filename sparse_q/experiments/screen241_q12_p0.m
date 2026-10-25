function out=screen241_q12_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4222:4226; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='q12_p0'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','fixed','opFixed',1);
b=base; b.opPolicy='q'; b.opActions=[1 2]; b.opAlpha=0.1; b.opGamma=0.9; b.opEpsStart=0.20; b.opEpsEnd=0.02; b.opEpsDecay=0.98; b.opExploreBonus=0;
c=base; c.opPolicy='random'; c.opActions=[1 2]; c.opExploreBonus=0;
d=base; d.opFixed=2;
e=base; e.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-Q12','C-Random12','D-DiffAll','E-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
