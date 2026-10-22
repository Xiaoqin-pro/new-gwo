function out=screen48_rgi_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN48_RGI_CONFIRM  New B=RGI and C=stall-only arms; A2-G1E is reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='rgi_confirm'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'rgiConsecFail',3,'rgiWorstFrac',0.5,'rgiSeedOffset',444444);
armB=base; armB.rgiMode='on';
armC=base; armC.rgiMode='stall';
algs={'SGWO_RGI','SGWO_RGI'}; labels={'B-RGI','C-StallRestart'};
states={armB,armC};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
