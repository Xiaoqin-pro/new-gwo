function out=rd1c_explore(seeds,maxFE,D)
%RD1C_EXPLORE  Final E-module refinement (see docs/10_RD1C_ADDENDUM.md).
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO'};
labels={'GWO','E-f30-alpha-r','E-f20-alpha-n'};
states=cell(1,3);
states{2}=struct('exploreMode','fixed','exploreShare',0.30,'roverCenter','alpha','roverDest','random');
states{3}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','novelty');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd1c',algs,funcs,seeds,D,maxFE,opt);
end
