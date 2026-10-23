function out=screen141_aslshade_p0(seeds,maxFE,D,funcs,tag)
%SCREEN141_ASLSHADE_P0  Adaptive-sparsity L-SHADE P0.
if nargin<1 || isempty(seeds), seeds=3864:3868; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='aslshade_p0'; end
common=struct('sparseK',10,'screenNearFrac',0.50,'kChoices',[10 25 50], ...
    'kWindowFrac',0.02,'epsExplore',0.10);
armA=common; armA.screenMode='dense';
armB=common; armB.screenMode='fixedK';
armC=common; armC.screenMode='randomK';
armD=common; armD.screenMode='adaptiveK';
algs=repmat({'ASLSHADE'},1,4);
labels={'A-Dense','B-FixedK10','C-RandomK','D-AdaptiveK'};
opt=struct('states',{ {armA,armB,armC,armD} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
