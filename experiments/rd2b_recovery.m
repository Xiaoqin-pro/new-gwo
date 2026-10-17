function out=rd2b_recovery(seeds,maxFE,D)
%RD2B_RECOVERY  Recovery-action screen: elite-memory shell vs trust-region expansion.
%   Pre-registered in docs/11_RD2B_ADDENDUM.md. S-stag-nov must reproduce
%   rd2a bitwise (cross-batch audit).
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','S-stag-nov','S2-elite','S3-exp1','S3-exp3'};
states=cell(1,5);
states{2}=struct('recoveryMode','stagnation','recoveryDest','novelty');
states{3}=struct('recoveryMode','stagnation','recoveryDest','elite','rescueScaleMult',1);
states{4}=struct('recoveryMode','stagnation','recoveryDest','alphaShell','rescueScaleMult',1);
states{5}=struct('recoveryMode','stagnation','recoveryDest','alphaShell','rescueScaleMult',3);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd2b',algs,funcs,seeds,D,maxFE,opt);
end
