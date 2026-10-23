function test_crowd_contract()
%TEST_CROWD_CONTRACT  extReplace='worst' must be bitwise identical to SGWO_STEER3; near/rand must act.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
 'extReplace','worst');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[B0,T0,i0]=SGWO_CROWD(fc,base,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'worst arm differs from SGWO_STEER3');
fprintf('  worst  BITWISE EQUAL | replacements=%d meanDist=%.4f\n',i0.ExtRepN,i0.ExtRepDistMean);
for m={'near','rand'}
    s=base; s.extReplace=m{1};
    [B,T,i]=SGWO_CROWD(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    fprintf('  %-5s ok FE=%d replacements=%d (worst arm: %d) meanDist=%.4f cost=%.6g\n',m{1},i.Evaluations,i.ExtRepN,i0.ExtRepN,i.ExtRepDistMean,B.Cost);
end
fprintf('test_crowd_contract PASS.\n');
end
