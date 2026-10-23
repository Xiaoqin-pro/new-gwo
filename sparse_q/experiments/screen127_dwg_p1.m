function out=screen127_dwg_p1(seeds,maxFE,D,funcs,tag)
%SCREEN127_DWG_P1  Dynamic wolf groups P1.
if nargin<1 || isempty(seeds), seeds=3744:3753; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='dwg_p1'; end
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
