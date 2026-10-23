function test_pilot_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4013; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'pilotFrac',0.05);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=PILOT_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
assert(any(strcmp(i.Winner,{'CMAES','LSHADE'})));
fprintf('pilot ok FE=%d pilot=%d final=%d winner=%s cmaP=%.6g lsP=%.6g best=%.6g\n', ...
 i.Evaluations,i.PilotFE,i.FinalFE,i.Winner,i.CMAESPilot,i.LSHADEPilot,B.Cost);
end
