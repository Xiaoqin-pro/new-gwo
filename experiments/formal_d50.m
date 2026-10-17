function out=formal_d50(seeds,maxFE,D)
%FORMAL_D50  Frozen-version formal batch (see docs/13_FREEZE.md).
%   CEC2017 D=50, 100000 true FE, F1 & F3-F30, seeds 3001:3030.
%   Six new-run variants: GWO (metrics + bitwise audit vs the audited table),
%   ANGWO-final, and four pre-registered ablation/documentation variants.
%   Strong baselines are NOT re-run: their audited 30-seed rows are merged in
%   post-processing (experiments/merge_audited.py), after verifying that this
%   pipeline reproduces them bitwise (tests/test_pipeline_external.m).
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
eStar=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
selfC=eStar; selfC.roverCenter='self';
novD=eStar;  novD.roverDest='novelty';
adapt=struct('exploreMode','adaptive','roverCenter','alpha','roverDest','random');
es2=eStar; es2.recoveryMode='stagnation'; es2.recoveryDest='elite'; es2.rescueScaleMult=1;
algs={'GWO','ANGWO','ANGWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO','ANGWO-final','ANGWO-self','ANGWO-novdest','ANGWO-adapt','ANGWO-ES2'};
states=cell(1,6); states{2}=eStar; states{3}=selfC; states{4}=novD; states{5}=adapt; states{6}=es2;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('formal',algs,funcs,seeds,D,maxFE,opt);
end
