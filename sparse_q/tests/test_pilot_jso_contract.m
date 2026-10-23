function test_pilot_jso_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4053; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'pilotFrac',0.20,'functionID',fid);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=PILOT_JSO_CEC(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12); assert(2*i.PilotFE+i.FinalFE==budget);
fprintf('pilot-jso ok FE=%d winner=%s best=%.6g\n',i.Evaluations,i.Winner,B.Cost);
end
