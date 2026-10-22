function out=screen65_steer_confirm2(seeds,maxFE,D,funcs,tag)
%SCREEN65_STEER_CONFIRM2  Faithful per-wolf steer arms; A2/A0 baselines are reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='steer_confirm2'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','succSteer',0.5,'steerLambda',0.5);
armB=common; armB.sdirSource='random';
armC=common; armC.sdirSource='g1';
armD=common; armD.sdirSource='random'; armD.ablateE=1;
algs=repmat({'SGWO_STEER'},1,3);
labels={'B-Steer-Rand','C-Steer-Dir','D-Steer-NoE'};
opt=struct(); opt.states={armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
