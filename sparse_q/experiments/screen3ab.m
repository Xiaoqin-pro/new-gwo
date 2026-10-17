function out=screen3ab(seeds,maxFE,D)
%SCREEN3AB  两条采样器臂上的配额决策对照（docs/04_SCREEN3.md）。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
strat=base; strat.screenPolicy='strat'; strat.g1Share=2/3; strat.stratG1='random'; strat.stratE='random';
wgt=base; wgt.screenPolicy='weighted';
% --- arm a: pinned strat ---
a1=strat; a1.quotaPolicy='fixed'; a1.quotaFixed=0.25;
a2=strat; a2.quotaPolicy='random';
a3=strat; a3.quotaPolicy='q';
optA=struct('states',{{a1,a2,a3}},'labels',{{'S3p-q25','S4p-random','S5p-q'}});
outA=run_batch_sq('sq3a',repmat({'SGWO'},1,3),funcs,seeds,D,maxFE,optA);
% --- arm b: weighted ---
b1=wgt; b1.quotaPolicy='fixed'; b1.quotaFixed=0.25;
b2=wgt; b2.quotaPolicy='random';
b3=wgt; b3.quotaPolicy='q';
optB=struct('states',{{b1,b2,b3}},'labels',{{'S3w-q25','S4w-random','S5w-q'}});
outB=run_batch_sq('sq3b',repmat({'SGWO'},1,3),funcs,seeds,D,maxFE,optB);
out=struct('A',outA,'B',outB);
end
