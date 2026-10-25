function out=screen298_fourarm_3001(seeds,maxFE,D,funcs,tag)
%SCREEN298_FOURARM_3001  四臂对比：两篇新外部 GWO 基线 + 提出算法 + 同池 GWO 对照。
%   种子 3001:3030 与既有主表（data/reference/audited_*_30seed.csv）一致，
%   便于与已审计的 IGWO / CLPSO / SPSO / HIDMS-PSO 等直接合并比较。
%   四臂：
%     A-GWO        冻结经典 GWO（同池对照，可交叉核对 reference 里的 GWO 结果）
%     B-MENGWO     2025 Sci Rep，DE 变异 + EPD + NPSR（论文复现）
%     C-IAGWO      2024 AI Review，PSO 速度 + IMF 权重 + Sigmoid 自适应（论文复现）
%     D-SVAD-GWO   提出算法（DiffA 差分槽位 + VMA 档案 + 稀疏评价）
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='fourarm_3001'; end
algs={'GWO','MENGWO','IAGWO','SVADGWO'};
labels={'A-GWO','B-MENGWO','C-IAGWO','D-SVAD-GWO'};
opt=struct('states',{ {struct(),struct(),struct(),struct()} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
