function out=screen104_dsep_p1(seeds,maxFE,D,funcs,tag)
%SCREEN104_DSEP_P1  Independent P1 replication of the adaptive separation reference.
if nargin<1 || isempty(seeds), seeds=3624:3633; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='dsep_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.dSepRef='box';
armB=common; armB.dSepRef='pop';
armC=common; armC.dSepRef='half';
algs=repmat({'SGWO_DSEP'},1,3);
labels={'A-DSEP-Box','B-DSEP-Pop','C-DSEP-Half'};
opt=struct('states',{ {armA,armB,armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
