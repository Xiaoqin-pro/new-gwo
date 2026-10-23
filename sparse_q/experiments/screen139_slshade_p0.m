function out=screen139_slshade_p0(seeds,maxFE,D,funcs,tag)
%SCREEN139_SLSHADE_P0  Sparse L-SHADE P0.
if nargin<1 || isempty(seeds), seeds=3839:3843; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='slshade_p0'; end
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
