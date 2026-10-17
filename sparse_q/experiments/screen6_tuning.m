function out=screen6_tuning(seeds,maxFE,D)
%SCREEN6_TUNING  调参轮（docs/06_TUNING.md）：K 与池比例扫描 + Q 参数最后一试。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs=repmat({'SGWO'},1,6);
labels={'T-S1-p38','T-S1-p25','T-S1-p38-K25','T-S1-p38-K10','T-S1-E50','T-Q-v2'};
states=cell(1,6);
mkuni=@(K,g2,e) struct('mode','sparse','K',K,'nG2',g2,'nE',e,'screenPolicy','random');
states{1}=mkuni(50,12,38);
states{2}=mkuni(50,25,25);
states{3}=mkuni(25,12,38);
states{4}=mkuni(10,12,38);
states{5}=mkuni(50,0,50);
q2=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','strat','g1Share',2/3, ...
    'stratG1','random','stratE','random','quotaPolicy','q','quotaFixed',0.25, ...
    'qAlpha',0.3,'qGamma',0.95,'qEpsStart',0.4,'qEpsEnd',0.02);
states{6}=q2;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq6',algs,funcs,seeds,D,maxFE,opt);
end
