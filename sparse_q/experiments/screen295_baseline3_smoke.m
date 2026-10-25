function out=screen295_baseline3_smoke(seeds,maxFE,D,funcs,tag)
%SCREEN295_BASELINE3_SMOKE  三个新增外部基线的开发集烟测（8 函数 x 2 新种子）。
%   目的：确认三份复现能跑、FE 精确、量级合理（与 GWO / SVAD-GWO 同池同种子）。
if nargin<1 || isempty(seeds), seeds=4484:4485; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='baseline3_smoke'; end
algs={'SVADGWO','GWO','MENGWO','DEElimGWO','CorrectedGWO','CorrectedGWO'};
labels={'SVAD-GWO','GWO','MENGWO','DE-Elim GWO','CorrGWO-c2','CorrGWO-c1'};
a1=struct('cgwoVariant','c2');
a2=struct('cgwoVariant','c1');
opt=struct('states',{ {struct(),struct(),struct(),struct(),a1,a2} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
