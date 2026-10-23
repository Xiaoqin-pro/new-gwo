function out=screen144_slshade_k25_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3858:3859; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='slshade_k25_dev'; end
common=struct('sparseK',25,'screenNearFrac',0.50);
armA=common; armA.screenPolicy='dense';
armB=common; armB.screenPolicy='dual';
algs=repmat({'SLSHADE'},1,2);
labels={'A-Dense','B-DualK25'};
opt=struct('states',{ {armA,armB} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
