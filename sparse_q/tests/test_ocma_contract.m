function test_ocma_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4057; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=CMAES_CEC(fc,base,[],N,seed+1000000); s=base; s.cmaOrthogonal=true; [Bo,To,io]=CMAES_CEC(fc,s,[],N,seed+1000000); assert(io.Evaluations==budget && numel(To)==budget && abs(To(end)-Bo.Cost)<1e-12); assert(~isequal(T,To)); fprintf('ocma ok FE=%d best=%.6g\n',io.Evaluations,Bo.Cost);
end
