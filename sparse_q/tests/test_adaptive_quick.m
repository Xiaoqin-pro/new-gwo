function test_adaptive_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',30000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000);
fprintf('adaptive best=%.6g FE=%d slots=%d/%d\n',B.Cost,i.Evaluations,i.Parameters.nG2,i.Parameters.nE);
assert(i.Evaluations==30000,'FE mismatch');
assert(all(diff(T)<=0),'trace not monotone');
assert(i.Parameters.nG2+i.Parameters.nE>=4,'allocation collapsed');
[B2,~,~]=SVADGWO2_cfg(f,st,seed+1000000);
assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),'not deterministic');
[B3,~,i3]=SVADGWO2_cfg(f,st,seed+1000000,'adaptSlots',0,'nG2',12,'nE',38);
fprintf('fixed 12/38 best=%.6g\n',B3.Cost);
assert(B3.Cost~=B.Cost,'adaptive identical to fixed - not applied');
fprintf('TEST_ADAPTIVE_QUICK PASS\n');
end
