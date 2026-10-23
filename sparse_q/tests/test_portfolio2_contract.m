function test_portfolio2_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4047; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'p2Split',0.5);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=PORTFOLIO2_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12); assert(i.CMAESFE==6000 && i.jSOFE==6000);
fprintf('portfolio2 ok FE=%d cma=%d jso=%d best=%.6g\n',i.Evaluations,i.CMAESFE,i.jSOFE,B.Cost);
end
