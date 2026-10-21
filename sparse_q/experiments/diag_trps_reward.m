function out=diag_trps_reward(seeds,maxFE,D,funcs,tag)
%DIAG_TRPS_REWARD  Diagnostic only: TRPS vs random trust-region, G2 off.
if nargin<1 || isempty(seeds), seeds=3986:3987; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 7 14 20 30]; end
if nargin<5 || isempty(tag), tag='trps_diag'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0);
armB=base; armB.trpsMode='trps'; armB.trpsWindow=1000; armB.trpsSeedOffset=888888;
armR=base; armR.trpsMode='random'; armR.trpsWindow=1000; armR.trpsSeedOffset=888888;
algs={'SGWO_TRPS','SGWO_TRPS'};
labels={'B-TRPS-G2off','R-RandomTR-G2off'};
states={armB,armR};
opt=struct('states',{states},'labels',{labels});
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
