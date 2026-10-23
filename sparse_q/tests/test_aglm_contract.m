function test_aglm_contract()
%TEST_AGLM_CONTRACT  none is bitwise equal; archive/random soft mixing actuate.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3990; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.mixMode='none';
[B0,T0,i0]=SGWO_AGLM(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'none differs from SGWO_STEER3');
fprintf('  none    BITWISE EQUAL | FE=%d\n',i0.Evaluations);
for m={'archive','random'}
    s=base; s.mixMode=m{1};
    [B,T,i]=SGWO_AGLM(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    assert(i.MixAppliedGens>0,'%s did not apply mixing',m{1});
    fprintf('  %-7s ok FE=%d applied=%d rate=%.3f dist=%.3f cost=%.6g\n', ...
        m{1},i.Evaluations,i.MixAppliedGens,i.MixAppliedRate,i.MixDistMean,B.Cost);
end
fprintf('test_aglm_contract PASS.\n');
end
