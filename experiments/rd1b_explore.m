function out=rd1b_explore(seeds,maxFE,D)
%RD1B_EXPLORE  Corrected E-module screen (after the rd1a padding-bug fix).
%   Pre-registered in docs/09_RD1B_ADDENDUM.md before running. Destination is
%   now 'random' (the novelty pick lost to random in rd1a); this batch varies
%   the sampling centre (self vs alpha) and the share rule (fixed/random/
%   adaptive). E-f10-self-r must reproduce rd1a's E-fixed10-nofilter bitwise.
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO','ANGWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','E-f10-self-r','E-rand-self-r','E-adapt-self-r', ...
    'E-f10-alpha-r','E-f10-alpha-n','E-f20-alpha-r'};
states=cell(1,7);
states{2}=struct('exploreMode','fixed','exploreShare',0.10,'roverCenter','self','roverDest','random');
states{3}=struct('exploreMode','random','roverCenter','self','roverDest','random');
states{4}=struct('exploreMode','adaptive','roverCenter','self','roverDest','random');
states{5}=struct('exploreMode','fixed','exploreShare',0.10,'roverCenter','alpha','roverDest','random');
states{6}=struct('exploreMode','fixed','exploreShare',0.10,'roverCenter','alpha','roverDest','novelty');
states{7}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd1b',algs,funcs,seeds,D,maxFE,opt);
end
