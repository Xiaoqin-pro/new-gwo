function out=screen87_emix_p1(seeds,maxFE,D,funcs,tag)
%SCREEN87_EMIX_P1  E-route internal mix rebalancing, 4 arms incl. reverse control (docs/80).
if nargin<1 || isempty(seeds), seeds=3574:3583; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='emix_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.eShellShare=0.50;
armB=common; armB.eShellShare=0.25;
armC=common; armC.eShellShare=0.00;
armD=common; armD.eShellShare=0.75;
algs=repmat({'SGWO_EMIX'},1,4);
labels={'A-Shell50','B-Shell25','C-Shell00','D-Shell75'};
opt=struct(); opt.states={armA,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
