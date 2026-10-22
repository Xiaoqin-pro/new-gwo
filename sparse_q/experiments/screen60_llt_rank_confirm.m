function out=screen60_llt_rank_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN60_LLT_RANK_CONFIRM  New arms only; A2 (E on) and A0 (E off) baselines are reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='llt_rank_confirm'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'lltWindow',7,'lltLeaders',3);
armB=common; armB.lltMode='rank';
armC=common; armC.lltMode='rankrand';
armD=common; armD.lltMode='rank'; armD.ablateE=1;
algs=repmat({'SGWO_LLT'},1,3);
labels={'B-LLT-Rank','C-LLT-RankRand','D-LLT-Rank-NoE'};
opt=struct(); opt.states={armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
