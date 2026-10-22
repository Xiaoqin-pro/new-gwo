function out=screen44_tsdr_audit(seeds,maxFE,D,funcs,tag)
%SCREEN44_TSDR_AUDIT  P0 passive trajectory-recovery audit.
if nargin<1 || isempty(seeds), seeds=3281:3285; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='tsdr_audit'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'tsdrMode','audit','tsdrConsecFail',3,'tsdrGainIQR',1);
algs={'SGWO_TSDR'}; labels={'TSD-R-Audit-G1E'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
