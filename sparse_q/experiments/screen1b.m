function out=screen1b(seeds,maxFE,D)
%SCREEN1B  一次修正（docs/01_PREREG.md 允许）：S2v2 = 名额分层选择
%   （E 占 qE；剩余 G 名额按 g1Share 分给 staleness-轮转的 G1 狼与随机 G2；
%    E 路 credit 加权中心分配、中心内随机），并给出“仅配额、全随机选择”的
%    后备骨架控制。S1 复跑用于跨批逐位审计。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs=repmat({'SGWO'},1,5);
labels={'S1-sparse-random','S2v2-strat-q50','S2v2-strat-q25','F-stratrand-q50','F-stratrand-q25'};
states=cell(1,5);
states{1}=struct('mode','sparse','K',50,'screenPolicy','random');
states{2}=struct('mode','sparse','K',50,'screenPolicy','strat','quotaPolicy','fixed','quotaFixed',0.50,'g1Share',0.5,'stratG1','rotate','stratE','credit');
states{3}=struct('mode','sparse','K',50,'screenPolicy','strat','quotaPolicy','fixed','quotaFixed',0.25,'g1Share',0.5,'stratG1','rotate','stratE','credit');
states{4}=struct('mode','sparse','K',50,'screenPolicy','strat','quotaPolicy','fixed','quotaFixed',0.50,'g1Share',0.5,'stratG1','random','stratE','random');
states{5}=struct('mode','sparse','K',50,'screenPolicy','strat','quotaPolicy','fixed','quotaFixed',0.25,'g1Share',0.5,'stratG1','random','stratE','random');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq1b',algs,funcs,seeds,D,maxFE,opt);
end
