function out=screen101_gaas_p1(seeds,maxFE,D,funcs,tag)
%SCREEN101_GAAS_P1  GAAS development screen: simplex vs off/random3 (docs/91).
if nargin<1 || isempty(seeds), seeds=3624:3633; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 5 6 7 8 9 10 11 13 15 20 24 30]; end
if nargin<5 || isempty(tag), tag='gaas_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.gaasMode='none';
armB=common; armB.gaasMode='simplex'; armB.gaasShellN=10; armB.gaasLineN=14;
armC=common; armC.gaasMode='random3'; armC.gaasShellN=10; armC.gaasLineN=14;
algs=repmat({'SGWO_GAAS'},1,3);
labels={'A-GAAS-Off','B-GAAS-Simplex','C-GAAS-Random3'};
opt=struct('states',{ {armA,armB,armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
