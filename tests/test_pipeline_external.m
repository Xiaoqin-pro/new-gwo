function test_pipeline_external()
%TEST_PIPELINE_EXTERNAL  Validate read-only external adapters against audited rows.
%   Each check reruns one (algorithm, function, seed) through runner_cec and
%   compares with the audited CSV. A mismatch means we are not calling the
%   exact audited implementation/protocol.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'experiments'));
cfg=newgwo_config();
csv10=readtable(cfg.auditRuns10,'TextType','string');
csv15=readtable(cfg.auditRuns15,'TextType','string');
fprintf('== test_pipeline_external ==\n');
checks={ ...
    'IGWO',       1, 3001, csv10, "IGWO", 50; ...
    'HIDMS-PSO',  1, 3001, csv15, "HIDMS-PSO-IndexCorrected", 40; ...
    'HCLPSO',     6, 3002, csv15, "HCLPSO-AuthorSource", 50; ...
    'DMS-PSO',   13, 3005, csv15, "DMS-PSO-SIS2005", 30; ...
    'SAQ-CSO',    1, 3001, csv15, "SAQ-CSO", 50; ...
    };
for c=1:size(checks,1)
    name=checks{c,1}; fid=checks{c,2}; seed=checks{c,3};
    csv=checks{c,4}; refName=checks{c,5}; N=checks{c,6};
    job=struct('algorithm',name,'fid',fid,'D',50,'seed',seed,'maxFE',100000,'N',N);
    res=runner_cec(job);
    ref=csv(csv.FunctionID==fid & csv.Seed==seed & csv.Algorithm==refName,:);
    assert(height(ref)==1,'reference row missing: %s F%d s%d',name,fid,seed);
    relerr=abs(res.BestCost-ref.FinalCost)/max(1,abs(ref.FinalCost));
    fprintf('  %-10s F%02d seed%d: ours=%.10g ref=%.10g relerr=%.3e\n', ...
        name,fid,seed,res.BestCost,ref.FinalCost,relerr);
    assert(relerr<1e-10,'%s does not reproduce audited result (F%d s%d)',name,fid,seed);
end
fprintf('== test_pipeline_external PASS ==\n');
end
