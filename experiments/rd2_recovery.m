function out=rd2_recovery(seeds,maxFE,D)
%RD2_RECOVERY  Round-2 screen of the stagnation-recovery module (S), E off.
%   Pre-registered in docs/08_HYPOTHESES_AND_GATES.md. Single mechanism under
%   test: recoveryMode/recoveryDest. Controls separate the stagnation trigger
%   (periodic) and the novelty-targeted destination (random destination).
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','S-stag-nov','S-stag-rand','S-per-nov'};
states=cell(1,4);
states{2}=struct('recoveryMode','stagnation','recoveryDest','novelty');
states{3}=struct('recoveryMode','stagnation','recoveryDest','random');
states{4}=struct('recoveryMode','periodic','recoveryDest','novelty');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd2',algs,funcs,seeds,D,maxFE,opt);
end
