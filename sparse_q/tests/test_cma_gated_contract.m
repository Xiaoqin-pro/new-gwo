function test_cma_gated_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4179; fid=13;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'cmaGateFraction',0.80,'cmaGateTol',1e-4);
fc=@(x)CEC2017Function(x,fid); [B,T,i]=CMA_GATED_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
fprintf('cma-gated ok FE=%d rounds=%d best=%.6g refine=%s progress=%.3g\n',i.Evaluations,i.Rounds,B.Cost,i.Refine,i.RecentProgress);
end
