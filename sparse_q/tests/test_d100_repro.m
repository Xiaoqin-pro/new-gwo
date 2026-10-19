function summary = test_d100_repro(pairs)
%TEST_D100_REPRO  Behavioural compatibility audit for the D=100 generalization run.
%
%   Re-runs archived frozen S-star (VAST-GWO) configurations with the CURRENT
%   working-tree implementation and compares the results bitwise against the
%   archived batches:
%     D=50 : results/final_20261016_215309  (frozen paper main batch)
%     D=100: results/fd100_20261016_232205  (archived D=100 tier)
%
%   summary = test_d100_repro()            % default 4 pairs
%   summary = test_d100_repro([1 3001; 9 3005; 13 3007; 24 3010])
%
%   Prints, per (D, function, seed): archived error, re-run error, relative
%   difference, and PASS/FAIL at 1e-12 relative tolerance.

here = fileparts(mfilename('fullpath'));
sqRoot = fileparts(here);
root = fileparts(sqRoot);
addpath(fullfile(root,'src'), fullfile(root,'data','cec2017'));
addpath(fullfile(sqRoot,'src'), fullfile(sqRoot,'experiments'), sqRoot, here);

if nargin < 1 || isempty(pairs)
    pairs = [1 3001; 9 3005; 13 3007; 24 3010];
end
tol = 1e-12;

base  = struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar = base; sStar.K = 10; sStar.screenPolicy = 'random';

cases = { struct('D',50,  'csv', fullfile(sqRoot,'results','final_20261016_215309','runs.csv')), ...
          struct('D',100, 'csv', fullfile(sqRoot,'results','fd100_20261016_232205','runs.csv')) };

summary = table();
for c = 1:numel(cases)
    D = cases{c}.D;
    T = readtable(cases{c}.csv, 'TextType','string');
    T = T(T.Status == "ok", :);
    fprintf('\n=== D=%d compatibility reproduction (archived: %s) ===\n', D, cases{c}.csv);
    fprintf('%4s %6s %18s %18s %12s %6s\n','Fn','Seed','archived error','re-run error','rel.diff','status');
    for p = 1:size(pairs,1)
        fid = pairs(p,1); seed = pairs(p,2);
        row = T(T.Algorithm=="S-star" & T.FunctionID==fid & T.Seed==seed, :);
        assert(height(row)==1, 'archived row not found for F%d s%d at D=%d', fid, seed, D);
        job = struct('algorithm','SGWO','label','S-star','fid',fid,'D',D, ...
                     'seed',seed,'maxFE',100000,'N',50,'state',sStar,'useProbe',true);
        res = runner_sgwo(job);
        arch = row.FinalError(1);
        re   = res.BestCost - 100*fid;
        rel  = abs(re - arch) / max(1, abs(arch));
        ok   = rel <= tol;
        fprintf('%4d %6d %18.8g %18.8g %12.2e %6s\n', fid, seed, arch, re, rel, string(ok));
        summary = [summary; table(D, fid, seed, arch, re, rel, ok, ...
            'VariableNames', {'D','FunctionID','Seed','archived','rerun','relDiff','pass'})]; %#ok<AGROW>
    end
end
fprintf('\nALL PASS: %d/%d\n', sum(summary.pass), height(summary));
assert(all(summary.pass), 'd100_repro:FAIL','Reproduction mismatch: current code is not bitwise-compatible with the archived runs.');
end
