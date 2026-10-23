function test_dar_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4023; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'darForceRestart',true);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=DAR_CMA_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
assert(i.Restarts>0 && i.ArchiveSize>0);
fprintf('dar-cma ok FE=%d restarts=%d archive=%d best=%.6g\n',i.Evaluations,i.Restarts,i.ArchiveSize,B.Cost);
end
