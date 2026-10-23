function out=screen116_drg_p1(seeds,maxFE,D,funcs,tag)
%SCREEN116_DRG_P1  Dual-role G1 development screen.
if nargin<1 || isempty(seeds), seeds=3624:3633; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='drg_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.drgMode='off';
armB=common; armB.drgMode='on'; armB.drgExploreN=20;
algs=repmat({'SGWO_DRG'},1,2);
labels={'A-DRG-Off','B-DRG-On'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
