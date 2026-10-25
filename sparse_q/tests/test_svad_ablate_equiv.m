function test_svad_ablate_equiv()
% SVADGWO_ablate('full') must be bitwise identical to SVADGWO.
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'src','ablation'));
cd(fullfile(root,'data','cec2017'));
ok=0; bad=0;
for fid=[1 4 13]
  for seed=[3459 3460]
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
    st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
        'upperBound',100*ones(1,50),'maxEvaluations',20000,'functionID',fid);
    f=@(x)CEC2017Function(x,fid);
    [B1,T1,~]=SVADGWO(f,st,[],50,seed+1000000);
    [B2,T2,~]=SVADGWO_ablate(f,st,'full',50,seed+1000000);
    d=abs(B1.Cost-B2.Cost)/max(1,abs(B2.Cost));
    if d==0 && isequal(T1,T2), ok=ok+1; fprintf('F%-2d seed %d: SAME  %.10g\n',fid,seed,B1.Cost);
    else bad=bad+1; fprintf('F%-2d seed %d: DIFF  %.10g vs %.10g  rel=%.3g\n',fid,seed,B1.Cost,B2.Cost,d); end
  end
end
fprintf('\nablate-full: %d identical, %d different\n',ok,bad);
end
