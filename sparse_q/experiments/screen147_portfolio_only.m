function out=screen147_portfolio_only(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3862:3863; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='portfolio_only'; end
arm=struct('portfolioSplit',0.50);
opt=struct('states',{ {arm} },'labels',{ {'C-Portfolio50'} });
out=run_batch_sq(tag,{'PORTFOLIO'},funcs(:),seeds(:),D,maxFE,opt);
end
