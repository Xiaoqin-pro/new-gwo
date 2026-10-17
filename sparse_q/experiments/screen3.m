function out=screen3(seeds,maxFE,D,qBest,sampler)
%SCREEN3  配额决策对照（预注册 docs/01 §SCREEN3）：
%   S3-best（固定配额最优） / S4-random-quota（同窗口同动作集均匀重抽）
%   / S5-q（6 态 × 3 动作 Q-learning）。
%   采样器与池沿用 SCREEN2 胜者（默认 weighted + 新池）。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
if nargin<4 || isempty(qBest), qBest=0.25; end
if nargin<5 || isempty(sampler), sampler='weighted'; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy',sampler);
algs=repmat({'SGWO'},1,3);
labels={sprintf('S3-best-q%02d',round(100*qBest)),'S4-random-quota','S5-q'};
states=cell(1,3);
s1=base; s1.quotaPolicy='fixed'; s1.quotaFixed=qBest; states{1}=s1;
s2=base; s2.quotaPolicy='random'; states{2}=s2;
s3=base; s3.quotaPolicy='q'; states{3}=s3;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq3',algs,funcs,seeds,D,maxFE,opt);
end
