function out=screen125_gh_shade_p1(seeds,maxFE,D,funcs,tag)
%SCREEN125_GH_SHADE_P1  GWO + SHADE subpopulation P1.
if nargin<1 || isempty(seeds), seeds=3729:3738; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='ghs_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.hybMode='off';
armB=common; armB.hybMode='shade'; armB.hybN=20;
algs=repmat({'SGWO_GHS'},1,2);
labels={'A-GHS-Off','B-GHS-Shade'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
