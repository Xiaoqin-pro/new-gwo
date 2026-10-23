function test_jso_cma_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4051; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'jsoFrac',0.50);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=JSO_CMA_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12); assert(i.InitPop==N);
fprintf('jso-cma ok FE=%d jso=%d cma=%d best=%.6g\n',i.Evaluations,i.jSOFE,i.CMAFE,B.Cost);
end
