function test_active_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4059; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid); s=base; s.cmaActive=true; [B,T,i]=CMAES_CEC(fc,s,[],N,seed+1000000); assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12); fprintf('active ok FE=%d best=%.6g\n',i.Evaluations,B.Cost);
end
