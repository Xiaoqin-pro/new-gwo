function out=screen43_vssm_audit(seeds,maxFE,D,funcs,tag)
%SCREEN43_VSSM_AUDIT  P0 passive successful-step scale audit.
if nargin<1 || isempty(seeds), seeds=3276:3280; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='vssm_audit'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'vssmMode','audit', ...
    'vssmWindow',30,'vssmMinSucc',5,'vssmRhoMin',0.5,'vssmRhoMax',1.5);
algs={'SGWO_VSSM'}; labels={'VSSM-Audit-G1E'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
