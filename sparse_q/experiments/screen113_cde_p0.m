function out=screen113_cde_p0(seeds,maxFE,D,funcs,tag)
%SCREEN113_CDE_P0  Cooperative differential expert P0.
if nargin<1 || isempty(seeds), seeds=3619:3623; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='cde_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.cdeMode='off';
armB=common; armB.cdeMode='on';
algs=repmat({'SGWO_CDE'},1,2);
labels={'A-CDE-Off','B-CDE-On'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
