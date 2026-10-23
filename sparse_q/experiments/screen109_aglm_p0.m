function out=screen109_aglm_p0(seeds,maxFE,D,funcs,tag)
%SCREEN109_AGLM_P0  Archive-guided soft leader mixing P0.
if nargin<1 || isempty(seeds), seeds=3619:3623; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='aglm_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.mixMode='none';
armB=common; armB.mixMode='archive';
armC=common; armC.mixMode='random';
algs=repmat({'SGWO_AGLM'},1,3);
labels={'A-AGLM-Off','B-AGLM-Archive','C-AGLM-Random'};
opt=struct('states',{ {armA,armB,armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
