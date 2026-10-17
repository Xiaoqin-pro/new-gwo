function out=rd3_promotion(seeds,maxFE,D)
%RD3_PROMOTION  Promotion batch (10 seeds): GWO, E*, S2-elite, E*+S2-elite.
%   Pre-registered in docs/12_RD3_AND_FREEZE_RULES.md. The frozen main method
%   is E* regardless; the S2 and combination rows are documentation controls.
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
eStar=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
sElite=struct('recoveryMode','stagnation','recoveryDest','elite','rescueScaleMult',1);
combo=eStar; fn=fieldnames(sElite);
for k=1:numel(fn), combo.(fn{k})=sElite.(fn{k}); end
algs={'GWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','E-f20-alpha-r','S2-elite','E+S2'};
states=cell(1,4); states{2}=eStar; states{3}=sElite; states{4}=combo;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd3',algs,funcs,seeds,D,maxFE,opt);
end
