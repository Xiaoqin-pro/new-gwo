function out=rd4_d100(seeds,maxFE)
%RD4_D100  Scalability tier at D=100 (pre-registered in docs/14_D100_ADDENDUM.md).
%   GWO vs ANGWO-final on 29 functions; pairing with audited IGWO/RASE rows is
%   restricted to their 12-function subset (F1, F3-F13) and reported as such.
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
D=100;
funcs=[1 3:30];
eStar=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
algs={'GWO','ANGWO'};
labels={'GWO','ANGWO-final'};
states=cell(1,2); states{2}=eStar;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('d100',algs,funcs,seeds,D,maxFE,opt);
end
