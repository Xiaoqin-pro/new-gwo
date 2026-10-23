function out=screen99_gaas_confirm(seeds,maxFE,D,funcs,tag,resume)
%SCREEN99_GAAS_CONFIRM  Geometry-aware archive simplex vs random-triplet control (docs/91).
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='gaas_confirm'; end
if nargin<6, resume=''; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armB=common; armB.gaasMode='simplex'; armB.gaasShellN=10; armB.gaasLineN=14;
armC=common; armC.gaasMode='random3'; armC.gaasShellN=10; armC.gaasLineN=14;
algs=repmat({'SGWO_GAAS'},1,2);
labels={'B-GAAS-Simplex','C-GAAS-Random3'};
opt=struct(); opt.states={armB,armC}; opt.labels=labels;
if ~isempty(resume), opt.resume=char(resume); end
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
