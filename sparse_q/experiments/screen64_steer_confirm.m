function out=screen64_steer_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN64_STEER_CONFIRM  New arms only; A2 (E on) and A0 (E off) baselines are reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='steer_confirm'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerLambda',0.5,'succSteer',0.5);
armV=common; armV.steerMode='vec';  armV.sdirSource='random';
armB=common; armB.steerMode='rand'; armB.sdirSource='random';
armC=common; armC.steerMode='dir';  armC.sdirSource='g1';
armD=common; armD.steerMode='rand'; armD.sdirSource='random'; armD.ablateE=1;
algs=repmat({'SGWO_STEER'},1,4);
labels={'V-Vec','B-Steer-Rand','C-Steer-Dir','D-Steer-NoE'};
opt=struct(); opt.states={armV,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
