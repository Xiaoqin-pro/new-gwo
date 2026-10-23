function out=screen153_split_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3870:3871; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='split_dev'; end
algs={'LSHADE','CMAES','PORTFOLIO','PORTFOLIO','PORTFOLIO'};
labels={'A-LSHADE','B-CMAES','C-P30','D-P50','E-P70'};
a30=struct('portfolioSplit',0.30); a50=struct('portfolioSplit',0.50); a70=struct('portfolioSplit',0.70);
opt=struct('states',{ {struct(),struct(),a30,a50,a70} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
