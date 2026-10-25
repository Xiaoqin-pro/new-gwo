function quick_budget_diag()
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src')); addpath('sparse_q/src'); cd(cfg.cecDir);
D=50;N=50; seeds=[3870 3871]; funcs=[1 4 7 10 13 20 24 30]; budgets=[30000 50000 70000 100000];
for f=funcs
 fprintf('F%d: ',f);
 for b=budgets
  vals=zeros(1,2);
  for j=1:2
   s=seeds(j); rng(261013000+f*10000+s,'twister'); pool=-100+200*rand(50,D);
   st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',b);
   [B,~,~]=LSHADE_CEC(@(x)CEC2017Function(x,f),st,[],N,s+1000000); vals(j)=B.Cost-100*f;
  end
  fprintf('B%d:%.3g/%.3g ',b/1000,vals(1),vals(2));
 end
 fprintf('\n');
end
end
