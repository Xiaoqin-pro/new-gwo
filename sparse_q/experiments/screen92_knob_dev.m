function out=screen92_knob_dev(seeds,maxFE,D,funcs,tag)
%SCREEN92_KNOB_DEV  filler-STEER + value-first evaluation ordering (3 new arms; frozen arm reused). docs/85
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='knob_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.fillerSteer=1; armB.evalOrder='index';
armC=common; armC.fillerSteer=0; armC.evalOrder='efirst';
armD=common; armD.fillerSteer=1; armD.evalOrder='efirst';
algs=repmat({'SGWO_KNOB'},1,3);
labels={'B-FillerSteer','C-EFirst','D-Both'};
opt=struct(); opt.states={armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
