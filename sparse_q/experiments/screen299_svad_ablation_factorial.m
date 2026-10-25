function out=screen299_svad_ablation_factorial(seeds,maxFE,D,funcs,tag,arms)
%SCREEN299_SVAD_ABLATION_FACTORIAL  SVAD-GWO 消融（29 函数 x 30 种子）。
%   种子 3001:3030 —— 与九臂主表同种子。Full 臂直接复用主表
%   fourarm_3001_20261025_010843 的 D-SVAD-GWO 结果（已用
%   test_svad_reuse_3001 在当前代码上逐点复现验证），因此本批只跑 5 个新臂。
%
%   目的：证明 E 与 DiffA 各自对框架有贡献（不检验协同作用）。
%     A-Full      完整算法（复用，不在此批运行）
%     B-Base      稀疏 GWO 基线：无档案、无差分（50/12/38 全为 GWO/壳填充）
%     C-Eonly     仅档案：E 槽位开启，差分关闭
%     D-Diffonly  仅差分：差分开启（仅狼群），无档案
%     E-NoSteer   关闭 STEER（随机流不变）
%     F-FixedDiff F(t) 固定为 1.0（无后期收缩）
%   所有臂恒定 N=50, M=100, K=10, 100k FE，同一初始种群。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svad_ablation_factorial'; end
if nargin<6 || isempty(arms), arms={'base','eonly','diffonly','nosteer','fixeddiff'}; end
labels=cell(1,numel(arms));
for k=1:numel(arms)
    switch lower(arms{k})
        case 'base',      labels{k}='B-Base';
        case 'eonly',     labels{k}='C-Eonly';
        case 'diffonly',  labels{k}='D-Diffonly';
        case 'nosteer',   labels{k}='E-NoSteer';
        case 'fixeddiff', labels{k}='F-FixedDiff';
        case 'noeslots',  labels{k}='G-NoEslots';
        case 'noeref',    labels{k}='H-NoEref';
        otherwise,        labels{k}=arms{k};
    end
end
st=cell(1,numel(arms));
for k=1:numel(arms), st{k}=struct('ablationVariant',arms{k}); end
algs=repmat({'SVADGWO_AB2'},1,numel(arms));
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
