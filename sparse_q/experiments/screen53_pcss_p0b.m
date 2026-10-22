function out=screen53_pcss_p0b(seeds,maxFE,D,funcs,tag)
%SCREEN53_PCSS_P0B  P0b passive surrogate-prediction audit (within-generation
%   Spearman gate, fresh seeds, PcssFE logged for exact generation splitting).
if nargin<1 || isempty(seeds), seeds=3321:3325; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='pcss_p0b'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'pcssMode','audit','pcssK',5,'pcssCap',256);
algs={'SGWO_PCSS'}; labels={'PCSS-Audit-P0b'}; states={base};
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
