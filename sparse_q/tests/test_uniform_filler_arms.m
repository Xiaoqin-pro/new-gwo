function test_uniform_filler_arms()
% Smoke check for the uniform-filler arms (baseg / eonlyg) and the invariant that
% redefining the filler does NOT touch Full, diffonly, or the legacy arms.
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'));
cd(fullfile(root,'data','cec2017'));
fid=4; seed=3471; budget=20000;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
    'upperBound',100*ones(1,50),'maxEvaluations',budget,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
arms={'full','diffonly','base','eonly','baseg','eonlyg'};
for k=1:numel(arms)
    [B,T,i]=SVADGWO_ablate2(f,st,arms{k},50,seed+1000000);
    assert(i.Evaluations==budget,sprintf('%s FE',arms{k}));
    assert(all(diff(T)<=0),sprintf('%s monotone',arms{k}));
    fprintf('%-9s best=%12.6g arch=%2d filler=%-5s useE=%d useDiff=%d\n', ...
        arms{k},B.Cost,i.ArchiveSize,i.Ablation.diffFiller,i.Ablation.useE,i.Ablation.useDiff);
end
% baseg must differ from base (different filler) but agree in structure
[B1,~,i1]=SVADGWO_ablate2(f,st,'base',50,seed+1000000);
[B2,~,i2]=SVADGWO_ablate2(f,st,'baseg',50,seed+1000000);
assert(i1.ArchiveSize==0 && i2.ArchiveSize==0,'base arms must have no archive');
assert(~strcmp(i1.Ablation.diffFiller,i2.Ablation.diffFiller),'fillers must differ');
fprintf('\nbase vs baseg differ (expected): %.6g vs %.6g\n',B1.Cost,B2.Cost);
fprintf('TEST_UNIFORM_FILLER_ARMS PASS\n');
end
