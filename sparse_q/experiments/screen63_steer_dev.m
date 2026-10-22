function out=screen63_steer_dev(seeds,maxFE,D,funcs,tag)
%SCREEN63_STEER_DEV  Re-validation of equal-length G1 perturbation on G1+E.
if nargin<1 || isempty(seeds), seeds=3379:3388; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='steer_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerLambda',0.5,'succSteer',0.5);
armA=common; armA.steerMode='none';
armV=common; armV.steerMode='vec';
armB=common; armB.steerMode='rand'; armB.sdirSource='random';
armC=common; armC.steerMode='dir';  armC.sdirSource='g1';
algs=repmat({'SGWO_STEER'},1,4);
labels={'A-Frozen','V-Vec','B-Steer-Rand','C-Steer-Dir'};
opt=struct(); opt.states={armA,armV,armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
