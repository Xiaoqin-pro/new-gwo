function test_seq_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000);
fprintf('batch FE=%d best=%.6g\n',i.Evaluations,B.Cost);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'evalMode','seq');
fprintf('seq   FE=%d best=%.6g\n',i2.Evaluations,B2.Cost);
assert(i2.Evaluations==20000,'seq FE mismatch');
assert(all(diff(T2)<=0),'seq trace not monotone');
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'evalMode','seq');
assert(abs(B3.Cost-B2.Cost)<=1e-12*max(1,abs(B2.Cost)),'seq not deterministic');
assert(B.Cost~=B2.Cost,'seq identical to batch - not applied');
fprintf('TEST_SEQ_QUICK PASS\n');
end
