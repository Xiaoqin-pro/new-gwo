function out=screen58_llt_anchor_dev(seeds,maxFE,D,funcs,tag)
%SCREEN58_LLT_ANCHOR_DEV  Dev check of the guarded (alpha-anchored) local topology.
if nargin<1 || isempty(seeds), seeds=3354:3358; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 14 30]; end
if nargin<5 || isempty(tag), tag='llt_anchor_dev'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'lltWindow',7,'lltLeaders',3);
armA=common; armA.lltMode='none';
armB=common; armB.lltMode='ring';
armD=common; armD.lltMode='anchor';
armC=common; armC.lltMode='anchorrand';
algs=repmat({'SGWO_LLT'},1,4);
labels={'A-FrozenG1E','B-LLT-Ring','D-LLT-Anchor','C-LLT-AnchorRand'};
opt=struct(); opt.states={armA,armB,armD,armC}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
