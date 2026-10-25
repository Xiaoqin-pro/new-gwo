function quick_pilot_features()
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src')); addpath('sparse_q/src'); cd(cfg.cecDir);
D=50;N=50; budget=20000; seeds=[3867 3868]; funcs=[1 4 7 10 13 20 24 30];
for f=funcs
 fprintf('F%d: ',f);
 for s=seeds
  rng(261013000+f*10000+s,'twister'); pool=-100+200*rand(50,D);
  fit=zeros(50,1); for i=1:50, fit(i)=CEC2017Function(pool(i,:),f); end
  init=min(fit)-100*f;
  st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
  fc=@(x)CEC2017Function(x,f);
  [Bc,Tc,~]=CMAES_CEC(fc,st,[],N,s+1000000); [Bl,Tl,~]=LSHADE_CEC(fc,st,[],N,s+1000000);
  c=Bc.Cost-100*f; l=Bl.Cost-100*f; trc=(Tc(15000)-Tc(20000))/max(abs(Tc(15000)),1); trl=(Tl(15000)-Tl(20000))/max(abs(Tl(15000)),1);
  fprintf('s%d init=%.2g c=%.2g l=%.2g c/init=%.2g l/init=%.2g tr=%.2g/%.2g | ',s,init,c,l,c/max(abs(init),1),l/max(abs(init),1),trc,trl);
 end
 fprintf('\n');
end
end
