function diag_s1_vs_strat()
%DIAG_S1_VS_STRAT  First-generation source composition: S1 vs strat-random.
%   Verifies the allocation actually matches theory (hypergeometric mean).
here=fileparts(mfilename('fullpath'));
sqRoot=fileparts(here);
root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cecDir=fullfile(root,'data','cec2017'); cd(cecDir);
fid=9; D=30; budget=3000;
rng(261013000+fid*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
f=@(x)CEC2017Function(x,fid);
a=st; a.mode='sparse'; a.K=50; a.screenPolicy='random';
b=st; b.mode='sparse'; b.K=50; b.screenPolicy='strat'; b.quotaPolicy='fixed'; ...
    b.quotaFixed=0.25; b.g1Share=2/3; b.stratG1='random'; b.stratE='random';
[BA,TA,iA]=SGWO(f,a,[],50,3001+1000000);
[BB,TB,iB]=SGWO(f,b,[],50,3001+1000000);
fprintf('S1    gen1 [G1 G2 E] = [%d %d %d]  best=%.6g  windows act%%=[%.2f %.2f %.2f]\n', ...
    iA.Gen1SrcCounts,BA.Cost,mean(iA.QuotaTrace(:,3)==1),mean(iA.QuotaTrace(:,3)==2),mean(iA.QuotaTrace(:,3)==3));
fprintf('strat gen1 [G1 G2 E] = [%d %d %d]  best=%.6g\n',iB.Gen1SrcCounts,BB.Cost);
fprintf('equalT=%d\n',isequal(TA,TB));
end
