function out=screen2(seeds,maxFE,D)
%SCREEN2  固定配额扫描（新池 G1=50/G2=12/E=38；docs/03_SCREEN2.md）。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs=repmat({'SGWO'},1,5);
labels={'S1-pool38','W-q25','W-q50','W-q75','S-q25-p38'};
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
mkW=@(q) setfields(base,struct('screenPolicy','weighted','quotaPolicy','fixed','quotaFixed',q));
states=cell(1,5);
states{1}=setfields(base,struct('screenPolicy','random'));
states{2}=mkW(0.25);
states{3}=mkW(0.50);
states{4}=mkW(0.75);
states{5}=setfields(base,struct('screenPolicy','strat','quotaPolicy','fixed','quotaFixed',0.25,'g1Share',2/3,'stratG1','random','stratE','random'));
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq2',algs,funcs,seeds,D,maxFE,opt);
end

function s=setfields(s,extra)
fn=fieldnames(extra);
for k=1:numel(fn), s.(fn{k})=extra.(fn{k}); end
end
