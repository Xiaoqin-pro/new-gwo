function test_stratgeo_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',30000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
vals=[];
for scr={'rand','stratgeo','stratcore'}
    [B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'screening',scr{1});
    assert(i.Evaluations==30000,[scr{1} ' FE']);
    [B2,~,~]=SVADGWO2_cfg(f,st,seed+1000000,'screening',scr{1});
    assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),[scr{1} ' det']);
    fprintf('%-10s best=%.6g\n',scr{1},B.Cost);
    vals(end+1)=B.Cost;
end
assert(numel(unique(vals))==3,'rules not distinct');
fprintf('TEST_STRATGEO_QUICK PASS\n');
end
