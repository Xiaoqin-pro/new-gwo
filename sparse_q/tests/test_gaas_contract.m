function test_gaas_contract()
%TEST_GAAS_CONTRACT  gaasMode='none' is bitwise equal to SGWO_STEER3; simplex/random3 actuate.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3987; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.gaasMode='none';
[B0,T0,i0]=SGWO_GAAS(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'none differs from SGWO_STEER3');
fprintf('  none    BITWISE EQUAL | FE=%d\n',i0.Evaluations);
for m={'simplex','random3'}
    s=base; s.gaasMode=m{1}; s.gaasShellN=10; s.gaasLineN=14;
    [B,T,i]=SGWO_GAAS(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    assert(all(i.GaasEval>0),'%s did not evaluate all GAAS branches',m{1});
    assert(i.GaasSimplexN==14,'simplex slot count mismatch');
    fprintf('  %-7s ok FE=%d eval(sh/line/simp)=%d/%d/%d GB=%d/%d/%d cost=%.6g\n', ...
        m{1},i.Evaluations,i.GaasEval(1),i.GaasEval(2),i.GaasEval(3), ...
        i.GaasGB(1),i.GaasGB(2),i.GaasGB(3),B.Cost);
end
fprintf('test_gaas_contract PASS.\n');
end
