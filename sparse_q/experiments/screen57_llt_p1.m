function out=screen57_llt_p1(seeds,maxFE,D,funcs,tag)
%SCREEN57_LLT_P1  Five-arm LLT experiment: E x topology, plus matched control.
if nargin<1 || isempty(seeds), seeds=3342:3351; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='llt_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'lltWindow',7,'lltLeaders',3);
armA=common; armA.lltMode='none';                       % frozen G1+E
armB=common; armB.lltMode='ring';                       % G1+E + local topology
armC=common; armC.lltMode='ringrand';                   % matched control (random leaders in window)
armD=common; armD.lltMode='ring';     armD.ablateE=1;   % local topology, E off
armE=common; armE.lltMode='none';     armE.ablateE=1;   % E off baseline
algs=repmat({'SGWO_LLT'},1,5);
labels={'A-FrozenG1E','B-LLT-Ring','C-LLT-RingRand','D-LLT-NoE','E-NoE-Frozen'};
opt=struct(); opt.states={armA,armB,armC,armD,armE}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
