function test_pipeline_d100()
%TEST_PIPELINE_D100  Validate the D=100 tier against the audited 12-function table.
%   Reruns IGWO (F1, seed 3001, D=100, 100k FE) through runner_cec and compares
%   with data/reference/audited_d100_12fn.csv. Requires the D100 input_data
%   files (copied read-only from the audited harness).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'),fullfile(root,'experiments'));
cfg=newgwo_config();
csv=readtable(fullfile(cfg.root,'data','reference','audited_d100_12fn.csv'),'TextType','string');
fprintf('== test_pipeline_d100 ==\n');
job=struct('algorithm','IGWO','fid',1,'D',100,'seed',3001,'maxFE',100000,'N',50);
res=runner_cec(job);
ref=csv(csv.FunctionID==1 & csv.Seed==3001 & csv.Algorithm=="IGWO",:);
assert(height(ref)==1,'audited D100 IGWO row missing');
relerr=abs(res.BestCost-ref.FinalCost)/max(1,abs(ref.FinalCost));
fprintf('  IGWO F01 seed3001 D100: ours=%.10g ref=%.10g relerr=%.3e\n',res.BestCost,ref.FinalCost,relerr);
assert(relerr<1e-10,'D100 pipeline does not reproduce audited IGWO');
fprintf('== test_pipeline_d100 PASS ==\n');
end
