function summary = test_d100_baseline_repro()
%TEST_D100_BASELINE_REPRO  Compatibility check for archived D=100 baselines.
%   Re-runs IGWO at D=100 with the current harness and compares against the
%   archived audited D=100 reference CSV (data/reference/audited_d100_12fn.csv).
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'), fullfile(root,'data','cec2017'));
addpath(fullfile(sqRoot,'src'), fullfile(sqRoot,'experiments'), sqRoot, here);
ref = readtable(fullfile(root,'data','reference','audited_d100_12fn.csv'),'TextType','string');
pairs = [1 3001; 6 3004; 9 3007; 13 3010];
fprintf('\n=== IGWO D=100 compatibility (archived audited_d100_12fn.csv) ===\n');
fprintf('%4s %6s %18s %18s %12s %6s\n','Fn','Seed','archived error','re-run error','rel.diff','status');
summary=table();
for p=1:size(pairs,1)
    fid=pairs(p,1); seed=pairs(p,2);
    row = ref(ref.Algorithm=="IGWO" & ref.FunctionID==fid & ref.Seed==seed,:);
    assert(height(row)==1,'IGWO archived row missing F%d s%d',fid,seed);
    job=struct('algorithm','IGWO','label','IGWO','fid',fid,'D',100,'seed',seed, ...
               'maxFE',100000,'N',50,'useProbe',true);
    res=runner_sgwo(job);
    arch=row.FinalError(1); re=res.BestCost-100*fid;
    rel=abs(re-arch)/max(1,abs(arch)); ok=rel<=1e-12;
    fprintf('%4d %6d %18.8g %18.8g %12.2e %6s\n',fid,seed,arch,re,rel,string(ok));
    summary=[summary; table(fid,seed,arch,re,rel,ok,'VariableNames',{'FunctionID','Seed','archived','rerun','relDiff','pass'})]; %#ok<AGROW>
end
fprintf('\nIGWO compatibility: %d/%d PASS\n', sum(summary.pass), height(summary));
end
