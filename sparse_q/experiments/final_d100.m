function out=final_d100(seeds,maxFE)
%FINAL_D100  可扩展性层（D=100，29 函数 × 种子 3001:3010，100k 真 FE）。
%   冻结 S* = 双路线池 + K=10 均匀随机评价（docs/07_FREEZE.md）。
%   变体：S*（K=10）、S1-K50、B1-dense-sync；与审计 IGWO/RASE-GWO 的对照
%   仅限其 12 函数子集（已在分析脚本中标注）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
D=100; funcs=[1 3:30];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
s1=base; s1.screenPolicy='random';
b1=base; b1.mode='dense-sync';
algs={'SGWO','SGWO','SGWO'}; labels={'S-star','S1-pool38','B1-dense-sync'};
states=cell(1,3); states{1}=sStar; states{2}=s1; states{3}=b1;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('fd100',algs,funcs,seeds,D,maxFE,opt);
end
