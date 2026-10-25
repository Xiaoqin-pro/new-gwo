function test_svad_reuse_3001()
% Prove the CURRENT SVADGWO.m reproduces the committed fourarm_3001 batch, so the
% Full arm of the ablation can be reused instead of re-run.
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
pts=[1 3001 2.345675e+05; 1 3015 2.277248e+05; 4 3001 5.556585e+02; 4 3015 4.608416e+02;
     13 3001 7.174563e+04; 13 3015 1.786456e+05; 20 3001 2.339157e+03; 20 3015 2.482013e+03;
     30 3001 3.929782e+07; 30 3015 2.893332e+07];
ok=0; bad=0;
for k=1:size(pts,1)
    fid=pts(k,1); seed=pts(k,2); ref=pts(k,3);
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,50);
    st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50), ...
        'upperBound',100*ones(1,50),'maxEvaluations',100000,'functionID',fid);
    [B,~,i]=SVADGWO(@(x)CEC2017Function(x,fid),st,[],50,seed+1000000);
    rel=abs(B.Cost-ref)/max(1,abs(ref));
    if rel<1e-6, ok=ok+1; else bad=bad+1; end
    fprintf('F%-2d s%d: now=%.8g  batch=%.8g  rel=%.2g  %s\n',fid,seed,B.Cost,ref,rel, ...
        ternary(rel<1e-6,'MATCH','DIFF'));
end
fprintf('\nreuse check: %d match, %d differ\n',ok,bad);
assert(bad==0,'Current SVADGWO.m does NOT reproduce the committed batch; cannot reuse.');
end
function s=ternary(c,a,b), if c, s=a; else, s=b; end, end
