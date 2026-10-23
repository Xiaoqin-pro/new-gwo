function out=screen119_css_early_p0(seeds,maxFE,D,funcs,tag)
%SCREEN119_CSS_EARLY_P0  Subspace exploration only in the first half of FE.
if nargin<1 || isempty(seeds), seeds=3654:3658; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='css_early_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.cssMode='off';
armB=common; armB.cssMode='on'; armB.cssN=20; armB.cssDims=15; armB.cssPhaseFrac=0.50;
algs=repmat({'SGWO_CSS'},1,2);
labels={'A-CSS-Off','B-CSS-Early'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
