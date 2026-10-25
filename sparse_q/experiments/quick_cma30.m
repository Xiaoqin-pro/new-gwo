function out=quick_cma30()
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src')); addpath('sparse_q/src'); cd(cfg.cecDir);
D=50;N=50;fid=1; seeds=[3867 3868]; vals=zeros(1,2);
for j=1:2
  s=seeds(j); rng(261013000+fid*10000+s,'twister'); pool=-100+200*rand(50,D);
  st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',30000);
  [B,~,~]=CMAES_CEC(@(x)CEC2017Function(x,fid),st,[],N,s+1000000); vals(j)=B.Cost-100*fid;
end
fprintf('CMA30 F1: %.6g %.6g\n',vals(1),vals(2));
end
