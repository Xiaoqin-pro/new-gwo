function out=screen121_css_early_confirm(seeds,maxFE,D,funcs,tag,resume)
%SCREEN121_CSS_EARLY_CONFIRM  Confirm CSS-Early vs frozen (docs/102).
if nargin<1 || isempty(seeds), seeds=3669:3698; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='css_early_confirm'; end
if nargin<6, resume=''; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.cssMode='off';
armB=common; armB.cssMode='on'; armB.cssN=20; armB.cssDims=15; armB.cssPhaseFrac=0.50;
algs=repmat({'SGWO_CSS'},1,2);
labels={'A-CSS-Off','B-CSS-Early'};
opt=struct(); opt.states={armA,armB}; opt.labels=labels;
if ~isempty(resume), opt.resume=char(resume); end
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
