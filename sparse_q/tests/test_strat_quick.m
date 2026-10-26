function test_strat_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'screening','strat','kG1',3,'kG2s',3,'kEs',4);
fprintf('strat334 FE=%d best=%.6g\n',i.Evaluations,B.Cost);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'screening','strat','kG1',2,'kG2s',4,'kEs',4);
fprintf('strat244 FE=%d best=%.6g\n',i2.Evaluations,B2.Cost);
[B0,T0,i0]=SVADGWO2_cfg(f,st,seed+1000000);
fprintf('rand     FE=%d best=%.6g\n',i0.Evaluations,B0.Cost);
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'screening','strat','kG1',3,'kG2s',3,'kEs',4);
assert(abs(B3.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),'strat not deterministic');
assert(B.Cost~=B0.Cost,'strat identical to rand - screening not applied');
fprintf('TEST_STRAT_QUICK PASS\n');
end
