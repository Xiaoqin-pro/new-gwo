function test_seq2_quick()
addpath('src'); addpath('sparse_q/src'); addpath('sparse_q/src/ablation');
cd('data/cec2017'); fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
a={SVADGWO2_cfg(f,st,seed+1000000); SVADGWO2_cfg(f,st,seed+1000000,'evalMode','seq');
   SVADGWO2_cfg(f,st,seed+1000000,'evalMode','seq','seqRank','maximin')};
for k=1:numel(a)
    fprintf('cfg%d best=%.6g\n',k,a{k}.Cost);
end
assert(numel(unique([a{1}.Cost a{2}.Cost a{3}.Cost]))==3,'seq ranks not distinct');
[B,T,i]=SVADGWO2_cfg(f,st,seed+1000000,'evalMode','seq','seqRank','maximin');
assert(i.Evaluations==20000 && all(diff(T)<=0));
fprintf('TEST_SEQ2_QUICK PASS\n');
end
