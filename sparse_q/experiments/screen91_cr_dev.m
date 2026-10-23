function out=screen91_cr_dev(seeds,maxFE,D,funcs,tag)
%SCREEN91_CR_DEV  Crowding replacement dev (2 new arms; frozen arm REUSED from steer_confirm2). docs/84
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='cr_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.extReplace='near';
armC=common; armC.extReplace='rand';
algs=repmat({'SGWO_CROWD'},1,2);
labels={'B-Crowd','C-RandSlot'};
opt=struct(); opt.states={armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
