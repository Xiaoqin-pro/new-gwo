function out=screen102_cr_p1(seeds,maxFE,D,funcs,tag)
%SCREEN102_CR_P1  Independent CR replication with all three arms.
if nargin<1 || isempty(seeds), seeds=3624:3633; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='cr_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.extReplace='worst';
armB=common; armB.extReplace='near';
armC=common; armC.extReplace='rand';
algs=repmat({'SGWO_CROWD'},1,3);
labels={'A-CR-Worst','B-CR-Near','C-CR-Rand'};
opt=struct('states',{ {armA,armB,armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
