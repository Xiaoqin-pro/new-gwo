function quick_cma40()
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src')); addpath('sparse_q/src'); cd(cfg.cecDir);
D=50;N=50;fid=1; seeds=[3867 3868]; vals=zeros(1,2); ls=zeros(1,2); budget=40000;
for j=1:2
  s=seeds(j); rng(261013000+fid*10000+s,'twister'); pool=-100+200*rand(50,D);
  st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
  fc=@(x)CEC2017Function(x,fid);
  [B,~,~]=CMAES_CEC(fc,st,[],N,s+1000000); vals(j)=B.Cost-100*fid;
  [B2,~,~]=LSHADE_CEC(fc,st,[],N,s+1000000); ls(j)=B2.Cost-100*fid;
end
fprintf('F1 budget40k CMA: %.6g %.6g | LS: %.6g %.6g\n',vals(1),vals(2),ls(1),ls(2));
end
