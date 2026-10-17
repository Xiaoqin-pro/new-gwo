function out=final_d50(seeds,maxFE,D)
%FINAL_D50  冻结版正式批（docs/07_FREEZE.md）：D=50，29 函数，30 种子，100k 真 FE。
%   新运行 5 变体：S*（S1-pool38-K10）、S1-pool38（K=50）、S3p-q25、S5p-q、
%   B1-dense-sync。B0/GWO/强基线经审计合并（只读复用）。
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
s1=base; s1.screenPolicy='random';
strat=base; strat.screenPolicy='strat'; strat.g1Share=2/3; strat.stratG1='random'; strat.stratE='random';
s3p=strat; s3p.quotaPolicy='fixed'; s3p.quotaFixed=0.25;
s5p=strat; s5p.quotaPolicy='q';
b1=base; b1.mode='dense-sync';
algs={'SGWO','SGWO','SGWO','SGWO','SGWO'};
labels={'S-star','S1-pool38','S3p-q25','S5p-q','B1-dense-sync'};
states=cell(1,5); states{1}=sStar; states{2}=s1; states{3}=s3p; states{4}=s5p; states{5}=b1;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('final',algs,funcs,seeds,D,maxFE,opt);
end
