function out=screen47_rgi_audit(seeds,maxFE,D,funcs,tag)
%SCREEN47_RGI_AUDIT  P0 passive rank-gated restart audit.
if nargin<1 || isempty(seeds), seeds=3291:3295; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='rgi_audit'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'rgiMode','audit','rgiConsecFail',3,'rgiWorstFrac',0.5);
algs={'SGWO_RGI'}; labels={'RGI-Audit-G1E'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
