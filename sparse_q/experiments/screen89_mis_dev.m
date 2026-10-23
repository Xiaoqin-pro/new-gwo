function out=screen89_mis_dev(seeds,maxFE,D,funcs,tag)
%SCREEN89_MIS_DEV  MIS-GWO dev screen (3 new arms; the frozen arm is REUSED from steer_confirm2, seeds 3071-3080).
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='mis_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.misIslands=2; armB.misMigrateOn=1; armB.misMigrateEvery=500;
armC=common; armC.misIslands=2; armC.misMigrateOn=0; armC.misMigrateEvery=500;
armD=common; armD.misIslands=5; armD.misMigrateOn=1; armD.misMigrateEvery=500;
algs=repmat({'SGWO_MIS'},1,3);
labels={'B-2Isl-Mig','C-2Isl-NoMig','D-5Isl-Mig'};
opt=struct(); opt.states={armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
