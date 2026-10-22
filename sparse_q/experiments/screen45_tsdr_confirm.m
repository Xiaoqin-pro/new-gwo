function out=screen45_tsdr_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN45_TSDR_CONFIRM  New C=TSD-R arm; A=G1+E and B=TSD-base are reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='tsdr_confirm'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'tsdMode','base','tsdrMode','on', ...
    'tsdrConsecFail',3,'tsdrGainIQR',1);
algs={'SGWO_TSD'}; labels={'C-TSDR'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
