function test_softpot_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'screening','softpot');
fprintf('softpot best=%.6g FE=%d\n',B.Cost,i.Evaluations);
assert(i.Evaluations==20000 && all(diff(T)<=0));
[B2,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'screening','softpot');
assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),'not deterministic');
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'screening','softpot','gammaA',2.0,'gammaR',1.0);
fprintf('softpot g2/1 best=%.6g\n',B3.Cost);
assert(B3.Cost~=B.Cost,'gamma has no effect');
fprintf('TEST_SOFTPOT_QUICK PASS\n');
end
