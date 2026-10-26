function test_corehyb_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=19; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'screening','corehyb','kLocal',3);
fprintf('corehyb kLocal=3 best=%.6g\n',B.Cost);
[B2,T2,i2]=SVADGWO2_cfg(f,st,seed+1000000,'screening','corehyb','kLocal',3);
assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),'corehyb not deterministic');
[B3,T3,i3]=SVADGWO2_cfg(f,st,seed+1000000,'screening','corehyb','kLocal',5);
fprintf('corehyb kLocal=5 best=%.6g\n',B3.Cost);
[B4,T4,i4]=SVADGWO2_cfg(f,st,seed+1000000,'screening','corephase','phaseThresh',0.5);
fprintf('corephase 0.5   best=%.6g\n',B4.Cost);
[B5,T5,i5]=SVADGWO2_cfg(f,st,seed+1000000,'screening','corephase','phaseThresh',0.3);
fprintf('corephase 0.3   best=%.6g\n',B5.Cost);
assert(i.Evaluations==20000 && i3.Evaluations==20000 && i4.Evaluations==20000);
fprintf('TEST_COREHYB_QUICK PASS\n');
end
