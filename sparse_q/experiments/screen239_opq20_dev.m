function out=screen239_opq20_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4218:4219; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='opq20_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'opPolicy','fixed','opFixed',1);
b=base; b.opFixed=2;
c=base; c.opPolicy='random'; c.opActions=[1 2 3 4];
d=base; d.opPolicy='q'; d.opActions=[1 2 3 4]; d.opAlpha=0.1; d.opGamma=0.9; d.opEpsStart=0.30; d.opEpsEnd=0.05; d.opEpsDecay=0.995; d.opExploreBonus=0.1;
e=base; e.succSteer=0;
algs={'SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3','SGWO_STEER3'};
labels={'A-Standard','B-DiffAll','C-RandomOp','D-QOp','E-NoSTEER'};
opt=struct('states',{ {base,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
