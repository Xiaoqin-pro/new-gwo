function out=screen5_promotion(seeds,maxFE,D)
%SCREEN5_PROMOTION  10 种子晋级复核（docs/05_SCREEN4.md）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
strat=base; strat.screenPolicy='strat'; strat.g1Share=2/3; strat.stratG1='random'; strat.stratE='random';
s3p=strat; s3p.quotaPolicy='fixed'; s3p.quotaFixed=0.25;
s4p=strat; s4p.quotaPolicy='random';
s5p=strat; s5p.quotaPolicy='q';
algs={'GWO','ANGWO','SGWO','SGWO','SGWO','SGWO','SGWO'};
labels={'GWO','B0-ANGWO','B1-dense-sync','S1-pool38','S3p-q25','S4p-random','S5p-q'};
states=cell(1,7);
states{2}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
states{3}=struct('mode','dense-sync');
states{4}=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','random');
states{5}=s3p; states{6}=s4p; states{7}=s5p;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq5',algs,funcs,seeds,D,maxFE,opt);
end
