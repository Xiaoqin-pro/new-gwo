function out=screen1(seeds,maxFE,D)
%SCREEN1  Pre-registered screen: B0/B1/GWO + S1 (random sparse) + S2 (directed).
%   Gates (docs/01_PREREG.md): G_S1 (S1 usable), G_S2a (S2 beats S1),
%   G_S2b (early FE20 + simple-multimodal improvement).
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','SGWO','SGWO','SGWO'};
labels={'GWO','B0-ANGWO','B1-dense-sync','S1-sparse-random','S2-sparse-directed'};
states=cell(1,5);
% B0: frozen ANGWO final configuration (read-only algorithm, frozen switches)
states{2}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
states{3}=struct('mode','dense-sync');
states{4}=struct('mode','sparse','K',50,'screenPolicy','random');
states{5}=struct('mode','sparse','K',50,'screenPolicy','directed','quotaPolicy','fixed','quotaFixed',0.5);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq1',algs,funcs,seeds,D,maxFE,opt);
end
