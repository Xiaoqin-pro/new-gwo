function out=screen123_css_elite_p1(seeds,maxFE,D,funcs,tag)
%SCREEN123_CSS_ELITE_P1  Elite-only subspace exploration P1.
if nargin<1 || isempty(seeds), seeds=3714:3723; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='css_elite_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.cssMode='off';
armB=common; armB.cssMode='on'; armB.cssN=10; armB.cssDims=15; armB.cssPhaseFrac=0.50; armB.cssSelect='elite';
algs=repmat({'SGWO_CSS'},1,2);
labels={'A-CSS-Off','B-CSS-Elite'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
