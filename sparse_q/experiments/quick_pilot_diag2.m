function quick_pilot_diag2()
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src')); addpath('sparse_q/src'); cd(cfg.cecDir);
D=50;N=50; budget=20000; seeds=[3867 3868]; funcs=[1 4 7 10 13 20 24 30];
for f=funcs
 fprintf('F%d: ',f);
 for s=seeds
  rng(261013000+f*10000+s,'twister'); pool=-100+200*rand(50,D);
  st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
  fc=@(x)CEC2017Function(x,f);
  [Bc,Tc,~]=CMAES_CEC(fc,st,[],N,s+1000000); [Bl,Tl,~]=LSHADE_CEC(fc,st,[],N,s+1000000);
  rc=relimp(Tc,15000,20000); rl=relimp(Tl,15000,20000);
  fprintf('s%d c=%.3g(tr%.2g) l=%.3g(tr%.2g) | ',s,Bc.Cost-100*f,rc,Bl.Cost-100*f,rl);
 end
 fprintf('\n');
end
end
function r=relimp(T,a,b)
x=T(a); y=T(b); r=(x-y)/max(abs(x),1);
end
