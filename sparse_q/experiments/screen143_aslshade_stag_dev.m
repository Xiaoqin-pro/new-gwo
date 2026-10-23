function out=screen143_aslshade_stag_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3856:3857; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 13]; end
if nargin<5 || isempty(tag), tag='aslshade_stag_dev'; end
common=struct('sparseK',10,'screenNearFrac',0.50,'kChoices',[10 25 50], ...
    'kWindowFrac',0.02,'epsExplore',0.10);
armA=common; armA.screenMode='dense';
armB=common; armB.screenMode='fixedK';
armC=common; armC.screenMode='stagnationK';
algs=repmat({'ASLSHADE'},1,3);
labels={'A-Dense','B-FixedK10','C-StagnationK'};
opt=struct('states',{ {armA,armB,armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
