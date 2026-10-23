function out=screen146_portfolio_compare(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3862:3863; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='portfolio_compare'; end
algs={'LSHADE','CMAES','PORTFOLIO'};
labels={'A-LSHADE','B-CMAES','C-Portfolio50'};
opt=struct('states',{ {struct(),struct(),struct('portfolioSplit',0.5)} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
