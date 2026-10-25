function out=screen296_baseline3_confirm30(seeds,maxFE,D,funcs,tag)
%SCREEN296_BASELINE3_CONFIRM30  三个新增外部基线的正式确认（29 函数 x 30 种子）。
%   种子与 SVAD-GWO 的 svadgwo_confirm30_20261025_000001 完全一致（3459:3488），
%   因此可直接与该批次逐函数配对（同一初始池、同一预算、同一探针）。
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='baseline3_confirm30'; end
algs={'MENGWO','DEElimGWO','CorrectedGWO','CorrectedGWO'};
labels={'MENGWO','DE-Elim GWO','CorrGWO-c2','CorrGWO-c1'};
a1=struct('cgwoVariant','c2');
a2=struct('cgwoVariant','c1');
opt=struct('states',{ {struct(),struct(),a1,a2} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
