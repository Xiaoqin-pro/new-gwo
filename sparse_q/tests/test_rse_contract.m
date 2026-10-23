function test_rse_contract()
%TEST_RSE_CONTRACT  off is bitwise equal to SGWO_STEER3; fixed/randstrat actuate.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3989; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.rseMode='off';
[B0,T0,i0]=SGWO_RSE(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'off differs from SGWO_STEER3');
fprintf('  off      BITWISE EQUAL | FE=%d\n',i0.Evaluations);
for m={'fixed','randstrat'}
    s=base; s.rseMode=m{1}; s.rseQuotas=[3 1 1 5];
    [B,T,i]=SGWO_RSE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    assert(sum(i.RseEval)==budget-N,'RSE evaluation accounting mismatch: %d',sum(i.RseEval));
    fprintf('  %-9s ok FE=%d route=%s cost=%.6g\n',m{1},i.Evaluations,mat2str(i.RseEval),B.Cost);
end
fprintf('test_rse_contract PASS.\n');
end
