function out=screen93_last_dev(seeds,maxFE,D,funcs,tag)
%SCREEN93_LAST_DEV  Initialization (OBL/LHS) + intra-generation centre coverage (3 new arms; frozen reused). docs/86
if nargin<1 || isempty(seeds), seeds=3071:3080; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='last_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.initMode='obl'; armB.centreCoverage=0;
armC=common; armC.initMode='lhs'; armC.centreCoverage=0;
armD=common; armD.initMode='runner'; armD.centreCoverage=1;
algs=repmat({'SGWO_LAST'},1,3);
labels={'B-OBLInit','C-LHSInit','D-CentreCover'};
opt=struct(); opt.states={armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
