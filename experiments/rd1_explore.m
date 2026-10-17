function out=rd1_explore(seeds,maxFE,D)
%RD1_EXPLORE  Round-1 screen of the exploration-duty module (E), S off.
%   Pre-registered in docs/08_HYPOTHESES_AND_GATES.md (gates fixed before this
%   batch). Single mechanism under test: exploreMode with fully specified
%   destinations (roverDest='novelty', roverK=8, sigma from recent successful
%   steps). Variants: fixed shares 0.05/0.10/0.20, random share, adaptive
%   share, and one destination control (fixed 0.10 without the novelty filter).
%   Dev protocol: D=30, maxFE=30000, functions [1 3 4 6 9 13 18 24],
%   seeds 3001:3005 (stage 1); promoted variant re-run on 3001:3010.
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO','ANGWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','E-fixed05','E-fixed10','E-fixed20','E-rand','E-adapt','E-fixed10-nofilter'};
states=cell(1,7);
states{2}=struct('exploreMode','fixed','exploreShare',0.05);
states{3}=struct('exploreMode','fixed','exploreShare',0.10);
states{4}=struct('exploreMode','fixed','exploreShare',0.20);
states{5}=struct('exploreMode','random');
states{6}=struct('exploreMode','adaptive');
states{7}=struct('exploreMode','fixed','exploreShare',0.10,'roverDest','random');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd1',algs,funcs,seeds,D,maxFE,opt);
end
