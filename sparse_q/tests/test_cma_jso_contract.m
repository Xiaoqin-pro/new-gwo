function test_cma_jso_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4177; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'cmaJsoFraction',0.85);
fc=@(x)CEC2017Function(x,fid); [B,T,i]=CMA_JSO_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
fprintf('cma-jso ok FE=%d rounds=%d best=%.6g cma=%d jso=%d\n',i.Evaluations,i.Rounds,B.Cost,i.CMAFE,i.JSOFE);
end
