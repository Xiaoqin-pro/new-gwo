function out=phase1_diagnosis(seeds,maxFE,D)
%PHASE1_DIAGNOSIS  Phase-1 behavioral diagnosis batch (pre-registered).
%   Runs the audited strong baselines on a stratified dev set with identical
%   novelty/FE instrumentation, to quantify:
%     A) stagnation episodes, recovery probability, recovery cost;
%     B) per-FE improvement events and useful-novelty rates;
%     C) the dev-set ranking that the new modules must improve upon.
%   Dev protocol (pre-registered in docs/08_HYPOTHESES_AND_GATES.md):
%     D=30, maxFE=30000, functions [1 3 4 6 9 13 18 24], seeds 3001:3005.
%   The diagnosis contains NO candidate mechanism - it only measures the
%   baseline behaviour that motivates the hypotheses.
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','IGWO','HIDMS-PSO','HCLPSO','DMS-PSO','SAQ-CSO'};
opt=struct();
out=run_batch_new('diag1',algs,funcs,seeds,D,maxFE,opt);
end
