function out=screen100_gaas_p0(seeds,maxFE,D,funcs,tag,resume)
%SCREEN100_GAAS_P0  GAAS premise audit: branch value of simplex vs line/shell (docs/91).
if nargin<1 || isempty(seeds), seeds=3619:3623; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='gaas_p0'; end
if nargin<6, resume=''; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.gaasMode='none';
armB=common; armB.gaasMode='simplex'; armB.gaasShellN=10; armB.gaasLineN=14;
algs=repmat({'SGWO_GAAS'},1,2);
labels={'A-GAAS-Off','B-GAAS-Simplex'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
if ~isempty(resume), opt.resume=char(resume); end
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
