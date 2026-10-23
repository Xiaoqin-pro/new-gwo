function out=screen126_dwg_p0(seeds,maxFE,D,funcs,tag)
%SCREEN126_DWG_P0  Dynamic wolf groups P0.
if nargin<1 || isempty(seeds), seeds=3739:3743; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='dwg_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.dwgMode='off';
armB=common; armB.dwgMode='on'; armB.dwgN1=25;
algs=repmat({'SGWO_DWG'},1,2);
labels={'A-DWG-Off','B-DWG-On'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
