function test_cmaes_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=4009; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=CMAES_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget); assert(isfinite(B.Cost)); assert(all(isfinite(T)));
fprintf('cmaes ok FE=%d rounds=%d best=%.6g sigma=%.4g\n',i.Evaluations,i.Rounds,B.Cost,i.Sigma);
end
