function test_gwo_cma_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4033; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'gwoFrac',0.30);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=GWO_CMA_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
fprintf('gwo-cma ok FE=%d gwoFE=%d cmaFE=%d pop=%d best=%.6g\n',i.Evaluations,i.GWOFE,i.CMAFE,i.GWOPopSize,B.Cost);
end
