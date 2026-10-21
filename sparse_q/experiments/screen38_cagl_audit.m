function out=screen38_cagl_audit(seeds,maxFE,D,funcs,tag)
%SCREEN38_CAGL_AUDIT  P0 passive leadership-collapse audit (behaviour unchanged).
if nargin<1 || isempty(seeds), seeds=3251:3255; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='cagl_audit'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'caglMode','audit','caglSeedOffset',333333);
algs={'SGWO_CAGL'}; labels={'Audit-G1E-G2off'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
