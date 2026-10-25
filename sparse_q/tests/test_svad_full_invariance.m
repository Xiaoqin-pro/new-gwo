function test_svad_full_invariance()
% The patched SVADGWO_core must reproduce the PRE-PATCH behaviour bit for bit
% when every ablation switch is at its proposed value.  Baseline = commit 1e99eae.
% The reference implementation is the version committed as 1e99eae.  Extract it
% into a scratch folder first:
%   git show 1e99eae:sparse_q/src/SVADGWO_core.m > _oldcore/SVADGWO_core_old.m
%   % rename the function and its call site to SVADGWO_core_old / SVADGWO_old
%   git show 1e99eae:sparse_q/src/SVADGWO.m      > _oldcore/SVADGWO_old.m
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
if ~exist(fullfile(root,'_oldcore','SVADGWO_old.m'),'file')
    error('test_svad_full_invariance:noBaseline', ...
        'Extract the 1e99eae reference implementation into _oldcore/ first (see header).');
end
addpath(fullfile(root,'_oldcore'));
cd(fullfile(root,'data','cec2017'));
ok=0; bad=0;
for fid=[1 4 13 20 30]
  for seed=[3459 3462]
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
    st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
        'upperBound',100*ones(1,50),'maxEvaluations',30000,'functionID',fid);
    f=@(x)CEC2017Function(x,fid);
    [B1,T1,i1]=SVADGWO_old(f,st,[],50,seed+1000000);
    [B2,T2,i2]=SVADGWO(f,st,[],50,seed+1000000);
    dCost=abs(B1.Cost-B2.Cost)/max(1,abs(B1.Cost));
    sameTrace=isequaln(T1,T2);
    sameArch=isequal(i1.FinalArchive,i2.FinalArchive);
    samePop=isequal(i1.FinalPopulation,i2.FinalPopulation);
    if dCost==0 && sameTrace && sameArch && samePop
        ok=ok+1; fprintf('F%-2d s%d: IDENTICAL  %.10g (arch %d)\n',fid,seed,B1.Cost,i1.ArchiveSize);
    else
        bad=bad+1;
        fprintf('F%-2d s%d: MISMATCH cost=%.10g/%.10g trace=%d arch=%d pop=%d\n', ...
            fid,seed,B1.Cost,B2.Cost,sameTrace,sameArch,samePop);
    end
  end
end
fprintf('\nFull-invariance: %d identical, %d mismatch\n',ok,bad);
assert(bad==0,'Full path changed: do not start the ablation batch.');
end
