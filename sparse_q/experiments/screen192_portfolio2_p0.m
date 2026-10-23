function out=screen192_portfolio2_p0(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4013:4017; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='portfolio2_p0'; end
algs={'CMAES','jSO','PORTFOLIO2','PORTFOLIO2'}; labels={'A-CMA','B-jSO','C-P50','D-P60'};
a=struct('p2Split',0.50); b=struct('p2Split',0.60);
opt=struct('states',{ {struct(),struct(),a,b} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
