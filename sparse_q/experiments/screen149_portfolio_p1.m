function out=screen149_portfolio_p1(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3884:3893; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='portfolio_p1'; end
algs={'LSHADE','CMAES','PORTFOLIO'};
labels={'A-LSHADE','B-CMAES','C-Portfolio50'};
armC=struct('portfolioSplit',0.50);
opt=struct('states',{ {struct(),struct(),armC} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
