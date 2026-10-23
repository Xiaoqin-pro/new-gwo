function test_hccma_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4043; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'hcShareF',0.70);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=HCCMA_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12); assert(i.EvalF>0 && i.EvalD>0);
fprintf('hccma ok FE=%d full=%d diag=%d best=%.6g\n',i.Evaluations,i.EvalF,i.EvalD,B.Cost);
end
