function out=screen297_gwo_paired30(seeds,maxFE,D,funcs,tag)
%SCREEN297_GWO_PAIRED30  在 3459:3488 上补跑冻结 GWO，使三个新外部基线与 GWO 可配对。
%   既有 GWO 结果只有 seeds 3001:3030（data/reference）与 3071:3100（final_ablation），
%   与本批种子不同；同池配对要求同种子，故补跑 870 次。
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='gwo_paired30'; end
algs={'GWO'};
labels={'GWO'};
opt=struct('states',{ {struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
