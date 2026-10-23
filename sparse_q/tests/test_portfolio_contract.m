function test_portfolio_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4011; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'portfolioSplit',0.5);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=PORTFOLIO_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget);
assert(i.CMAESFE==6000 && i.LSHADEFE==6000);
assert(abs(B.Cost-min(i.CMAESBest,i.LSHADEBest))<1e-12);
fprintf('portfolio ok FE=%d cmaFE=%d lsFE=%d cma=%.6g ls=%.6g best=%.6g\n', ...
 i.Evaluations,i.CMAESFE,i.LSHADEFE,i.CMAESBest,i.LSHADEBest,B.Cost);
end
