function test_defer_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',30000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000);
fprintf('nodefer  best=%.6g FE=%d\n',B.Cost,i.Evaluations);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'defer',1);
fprintf('defer    best=%.6g FE=%d\n',B2.Cost,i2.Evaluations);
assert(i2.Evaluations==30000,'defer FE mismatch');
assert(all(diff(T2)<=0),'defer trace not monotone');
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'defer',1);
assert(abs(B3.Cost-B2.Cost)<=1e-12*max(1,abs(B2.Cost)),'defer not deterministic');
assert(B.Cost~=B2.Cost,'defer identical to nodefer - not applied');
fprintf('TEST_DEFER_QUICK PASS\n');
end
