function out=screen62_red_dev(seeds,maxFE,D,funcs,tag)
%SCREEN62_RED_DEV  Redundancy-aware screening dev batch (audit + two doses).
if nargin<1 || isempty(seeds), seeds=3369:3378; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='red_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'redMaxDraw',5);
armA=common; armA.redMode='audit'; armA.redEps=0.02;
armB=common; armB.redMode='drop';  armB.redEps=0.02;
armC=common; armC.redMode='drop';  armC.redEps=0.005;
algs=repmat({'SGWO_RED'},1,3);
labels={'A-RED-Audit','B-RED-002','C-RED-0005'};
opt=struct(); opt.states={armA,armB,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
