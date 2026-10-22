function out=screen59_llt_rank_dev(seeds,maxFE,D,funcs,tag)
%SCREEN59_LLT_RANK_DEV  Powered dev comparison of the rank-gated local topology.
if nargin<1 || isempty(seeds), seeds=3359:3368; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='llt_rank_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'lltWindow',7,'lltLeaders',3);
armA=common; armA.lltMode='none';
armB=common; armB.lltMode='ring';
armC=common; armC.lltMode='rank';
armR=common; armR.lltMode='rankrand';
algs=repmat({'SGWO_LLT'},1,4);
labels={'A-FrozenG1E','B-LLT-Ring','C-LLT-Rank','R-LLT-RankRand'};
opt=struct(); opt.states={armA,armB,armC,armR}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
