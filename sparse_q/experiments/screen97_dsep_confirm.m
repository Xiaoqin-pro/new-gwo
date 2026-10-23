function out=screen97_dsep_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN97_DSEP_CONFIRM  Adaptive separation reference vs constant-half control (frozen reused). docs/90
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='dsep_confirm'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.dSepRef='pop';
armC=common; armC.dSepRef='half';
algs=repmat({'SGWO_DSEP'},1,2);
labels={'B-DSEP-Pop','C-DSEP-Half'};
opt=struct(); opt.states={armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
