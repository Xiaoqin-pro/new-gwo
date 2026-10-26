function test_stratshare_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',50000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'screening','rand','adaptSlots',0,'nG2',12,'nE',38,'adaptK',0);
fprintf('rand       %.6g\n',B.Cost);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'screening','stratshare','qG1',0.4,'qG2',0.3,'adaptSlots',0,'nG2',12,'nE',38,'adaptK',0);
fprintf('strat 4/3/3 %.6g  FE=%d\n',B2.Cost,i2.Evaluations);
assert(i2.Evaluations==50000,'FE');
assert(all(diff(T2)<=0),'mono');
[B3,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'screening','stratshare','qG1',0.4,'qG2',0.3,'adaptSlots',0,'nG2',12,'nE',38,'adaptK',0);
assert(abs(B3.Cost-B2.Cost)<=1e-12*max(1,abs(B2.Cost)),'det');
assert(B.Cost~=B2.Cost,'not applied');
% also with adaptive K (quota must rescale)
[B4,~,i4]=SVADGWO2_cfg(f,st,seed+1000000,'screening','stratshare','qG1',0.4,'qG2',0.3,'adaptSlots',0,'nG2',12,'nE',38,'adaptK',1,'Kmin',4,'Kmax',20,'stallTol',2000);
fprintf('strat+adaptK %.6g rounds=%d\n',B4.Cost,i4.Rounds);
assert(i4.Evaluations==50000,'FE2');
fprintf('TEST_STRATSHARE_QUICK PASS\n');
end
