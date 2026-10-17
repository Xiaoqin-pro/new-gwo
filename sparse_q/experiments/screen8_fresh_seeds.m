function out=screen8_fresh_seeds(seeds,maxFE,D)
%SCREEN8  新种子（3011:3020，从未使用的 dev 种子）上的 S* 选择批。
if nargin<1 || isempty(seeds), seeds=3011:3020; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
mkuni=@(K,g2,e) struct('mode','sparse','K',K,'nG2',g2,'nE',e,'screenPolicy','random');
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
strat=base; strat.screenPolicy='strat'; strat.g1Share=2/3; strat.stratG1='random'; strat.stratE='random';
s3=strat; s3.quotaPolicy='fixed'; s3.quotaFixed=0.25;
algs=repmat({'SGWO'},1,4);
labels={'S1-p38','S1-p38-K10','S1-E50','S3p-q25'};
states=cell(1,4);
states{1}=mkuni(50,12,38);
states{2}=mkuni(10,12,38);
states{3}=mkuni(50,0,50);
states{4}=s3;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq8',algs,funcs,seeds,D,maxFE,opt);
end
