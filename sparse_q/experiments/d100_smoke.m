function out=d100_smoke(seed)
%D100_SMOKE  Seven-algorithm D=100 smoke run (1 function x 1 seed x 100k FE).
%   Verifies: 4-worker parallel start, exact true-FE accounting for every
%   algorithm, atomic per-job storage, and per-algorithm wall-clock timing.
if nargin<1 || isempty(seed), seed=3999; end
D=100; funcs=1; seeds=seed; maxFE=100000;
algs={'SGWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'};
labels={'VAST-GWO','GWO','IGWO','HAGWO','PSO','CLPSO','AOGWO'};
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
states=cell(1,7); states{1}=sStar;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('d100smoke',algs,funcs,seeds,D,maxFE,opt);
T=readtable(fullfile(out.outDir,'runs.csv'));
disp(T(:,{'Algorithm','FunctionID','Seed','Status','BestCost','Evaluations','ProbeFE','Seconds','Rounds'}));
fprintf('smoke summary: ok=%d failed=%d\n',sum(T.Status=="ok"),sum(T.Status~="ok"));
assert(all(T.Status=="ok"),'smoke:FAIL','Some smoke runs failed.');
assert(all(T.Evaluations==maxFE) && all(T.ProbeFE==maxFE),'smoke:FE','FE accounting mismatch.');
fprintf('per-algorithm seconds: '); 
for i=1:height(T), fprintf('%s=%.1fs ',T.Algorithm(i),T.Seconds(i)); end
fprintf('\n');
end
