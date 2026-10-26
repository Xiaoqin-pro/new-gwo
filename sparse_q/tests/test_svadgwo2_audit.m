function test_svadgwo2_audit()
% Structural audit for the final SVAD-GWO v2 structure (STEER removed).
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'));
cd(fullfile(root,'data','cec2017'));
budget=30000; fid=4; seed=3471;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
    'upperBound',100*ones(1,50),'maxEvaluations',budget,'functionID',fid);
f=@(x)CEC2017Function(x,fid);
arms={'full','base','eonly','diffonly','fixeddiff'};
fprintf('%-9s %12s %7s %5s %6s %6s %6s\n','arm','best','FE','arch','M100','mono','det');
for k=1:numel(arms)
    arm=arms{k};
    [B,T,i]=SVADGWO2_ablate(f,st,arm,50,seed+1000000);
    assert(i.Evaluations==budget,sprintf('%s FE',arm));
    assert(all(diff(T)<=0),sprintf('%s monotone',arm));
    assert(abs(T(end)-B.Cost)<=1e-12*max(1,abs(B.Cost)),sprintf('%s T(end)',arm));
    assert((i.Parameters.nG2+i.Parameters.nE+50)==100,sprintf('%s slots',arm));
    assert(strcmp(i.Ablation.diffFiller,'gwo'),sprintf('%s filler',arm));
    [B2,~,~]=SVADGWO2_ablate(f,st,arm,50,seed+1000000);
    det=abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost));
    assert(det,sprintf('%s determinism',arm));
    if any(strcmp(arm,{'base','diffonly'}))
        assert(i.ArchiveSize==0,sprintf('%s should have no archive, got %d',arm,i.ArchiveSize));
    else
        assert(i.ArchiveSize>0,sprintf('%s should have an archive',arm));
    end
    fprintf('%-9s %12.6g %7d %5d %6d %6d %6d\n',arm,B.Cost,i.Evaluations, ...
        i.ArchiveSize,1,all(diff(T)<=0),det);
end
[Bf,~,~]=SVADGWO2(f,st,[],50,seed+1000000);
[Ba,Ta,~]=SVADGWO2_ablate(f,st,'full',50,seed+1000000);
d=abs(Bf.Cost-Ba.Cost)/max(1,abs(Ba.Cost));
assert(d==0,'SVADGWO2 differs from ablate full');
fprintf('\nSVADGWO2 == ablate full : rel=%.3g\n',d);
fprintf('TEST_SVADGWO2_AUDIT PASS\n');
end
