function out=screen148_portfolio_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3879:3883; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='portfolio_p0'; end
algs={'LSHADE','CMAES','PORTFOLIO'};
labels={'A-LSHADE','B-CMAES','C-Portfolio50'};
armC=struct('portfolioSplit',0.50);
opt=struct('states',{ {struct(),struct(),armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
