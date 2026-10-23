function out=screen140_slshade_p1(seeds,maxFE,D,funcs,tag)
%SCREEN140_SLSHADE_P1  Sparse L-SHADE independent P1.
if nargin<1 || isempty(seeds), seeds=3844:3853; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='slshade_p1'; end
common=struct('sparseK',10,'screenNearFrac',0.50);
armA=common; armA.screenPolicy='dense';
armB=common; armB.screenPolicy='random';
armC=common; armC.screenPolicy='near';
armD=common; armD.screenPolicy='dual';
algs=repmat({'SLSHADE'},1,4);
labels={'A-Dense','B-RandomK','C-NearK','D-DualK'};
opt=struct('states',{ {armA,armB,armC,armD} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
