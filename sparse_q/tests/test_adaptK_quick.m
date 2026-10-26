function test_adaptK_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',50000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'adaptSlots',0,'nG2',12,'nE',38);
fprintf('fixedK  best=%.6g rounds=%d\n',B.Cost,i.Rounds);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'adaptSlots',0,'nG2',12,'nE',38,'adaptK',1,'Kmin',4,'Kmax',25);
fprintf('adaptK  best=%.6g rounds=%d\n',B2.Cost,i2.Rounds);
assert(i2.Evaluations==50000,'FE mismatch');
assert(all(diff(T2)<=0),'trace not monotone');
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'adaptSlots',0,'nG2',12,'nE',38,'adaptK',1,'Kmin',4,'Kmax',25);
assert(abs(B3.Cost-B2.Cost)<=1e-12*max(1,abs(B2.Cost)),'not deterministic');
assert(B.Cost~=B2.Cost,'adaptK not applied');
assert(i2.Rounds~=i.Rounds,'round count unchanged - K not varying');
fprintf('TEST_ADAPTK_QUICK PASS\n');
end
