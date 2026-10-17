function test_igwo_runner()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here);
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),sqRoot,'D:\111\Desktop\噜噜\基础版狼群\NEW_GWO_2026\src');
job=struct('algorithm','IGWO','fid',6,'D',50,'seed',3031,'maxFE',20000,'N',50);
res=runner_sgwo(job);
fprintf('IGWO via runner_sgwo: F%d s%d best=%.6g FE=%d ok\n',res.FunctionID,res.Seed,res.BestCost,res.Evaluations);
end
