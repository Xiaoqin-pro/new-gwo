function out=screen7_final_q(seeds,maxFE,D)
%SCREEN7  Q 的最后一次改进尝试（先验初始化 + 快速 ε 衰减），dev 种子 3001:3010。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
strat=base; strat.screenPolicy='strat'; strat.g1Share=2/3; strat.stratG1='random'; strat.stratE='random';
q3=strat; q3.quotaPolicy='q'; q3.qInitPrior=1.0; q3.qAlpha=0.2; q3.qGamma=0.9; q3.qEpsStart=0.15; q3.qEpsEnd=0.02;
s3=strat; s3.quotaPolicy='fixed'; s3.quotaFixed=0.25;
s4=strat; s4.quotaPolicy='random';
algs=repmat({'SGWO'},1,3); labels={'Q-v3-prior','S3p-q25','S4p-random'};
states=cell(1,3); states{1}=q3; states{2}=s3; states{3}=s4;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq7',algs,funcs,seeds,D,maxFE,opt);
end
