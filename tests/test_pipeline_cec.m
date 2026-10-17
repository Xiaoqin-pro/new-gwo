function test_pipeline_cec()
%TEST_PIPELINE_CEC  Validate the whole runner against the audited protocol.
%   Our fresh GWO must reproduce the audited GWO rows of
%   data/reference/audited_10algo_30seed.csv bit-for-bit: identical init pool
%   (initSeed protocol), identical search seed, identical RNG consumption.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'experiments'));
cfg=newgwo_config();
fprintf('== test_pipeline_cec ==\n');
csv=readtable(cfg.auditRuns10,'TextType','string');
checks=[1 3001; 6 3002; 13 3005];
for c=1:size(checks,1)
    fid=checks(c,1); seed=checks(c,2);
    job=struct('algorithm','GWO','fid',fid,'D',50,'seed',seed,'maxFE',100000,'N',50);
    res=runner_cec(job);
    ref=csv(csv.FunctionID==fid & csv.Seed==seed & csv.Algorithm=="GWO",:);
    assert(height(ref)==1,'audited reference row not found for F%d seed%d',fid,seed);
    exact=isequal(res.BestCost,ref.FinalCost);
    relerr=abs(res.BestCost-ref.FinalCost)/max(1,abs(ref.FinalCost));
    fprintf('  F%02d seed%d: ours=%.10g ref=%.10g exact=%d relerr=%.3e\n', ...
        fid,seed,res.BestCost,ref.FinalCost,exact,relerr);
    assert(relerr<1e-12,'pipeline does not reproduce audited GWO (F%d seed%d)',fid,seed);
end
fprintf('== test_pipeline_cec PASS ==\n');
end
