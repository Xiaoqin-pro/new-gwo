function out=screen1c(seeds,maxFE,D)
%SCREEN1C  Corrected fix batch (SCREEN1B redo after the dispatch bug):
%   名额分层骨架（strat）在池比例分配（g1Share=2/3）下的
%   informed（rotate+credit） vs random-within-strata，以及 qE 份额趋势。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs=repmat({'SGWO'},1,5);
labels={'S1-sparse-random','P-prop25-rot','P-prop25-rand','P-prop50-rand','P-prop75-rand'};
states=cell(1,5);
states{1}=struct('mode','sparse','K',50,'screenPolicy','random');
mk=@(q,rot) struct('mode','sparse','K',50,'screenPolicy','strat','quotaPolicy','fixed','quotaFixed',q, ...
    'g1Share',2/3,'stratG1',rot,'stratE',rot);
states{2}=mk(0.25,'rotate'); states{2}.stratE='credit';
states{3}=mk(0.25,'random');
states{4}=mk(0.50,'random');
states{5}=mk(0.75,'random');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq1c',algs,funcs,seeds,D,maxFE,opt);
end
