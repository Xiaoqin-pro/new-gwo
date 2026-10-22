function test_vfa_contract()
%TEST_VFA_CONTRACT  none/shadow must be bitwise identical to the frozen final algorithm.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BA,TA]=SGWO_STEER3(fc,base,[],N,seed+1000000);
for mode={'none','shadow'}
    s=base; s.vfaMode=mode{1};
    [B,T,i1]=SGWO_VFA(fc,s,[],N,seed+1000000);
    ok=isequal(TA,T) && BA.Cost==B.Cost;
    fprintf('  %-7s %s | admits=%d size=%d distE=%.4f gap=%.3f evalNear=%d/%d impNear=%d/%d\n', ...
        mode{1},ternary(ok,'BITWISE EQUAL','DIFFERS'),i1.VfaAdmits,i1.VfaSize,i1.VfaDistEMed,i1.VfaGapMed, ...
        i1.VfaEvalNear,i1.VfaEvalTot,i1.VfaImpNear,i1.VfaImpTot);
    assert(ok,'VFA %s is not bitwise identical',mode{1});
end
s=base; s.vfaMode='active';
[B2,T2,i2]=SGWO_VFA(fc,s,[],N,seed+1000000);
assert(i2.Evaluations==budget && all(diff(T2)<=0),'active run broken');
fprintf('  active  ok FE=%d admits=%d size=%d cost=%.6g\n',i2.Evaluations,i2.VfaAdmits,i2.VfaSize,B2.Cost);
fprintf('test_vfa_contract PASS.\n');
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
