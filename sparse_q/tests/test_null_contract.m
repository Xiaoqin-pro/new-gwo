function test_null_contract()
%TEST_NULL_CONTRACT  nullOffset=0 must be bitwise identical to SGWO_STEER3; offset != 0 must differ.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'nullOffset',0);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BN,TN]=SGWO_NULL(fc,base,[],N,seed+1000000);
assert(isequal(TF,TN) && BF.Cost==BN.Cost,'nullOffset=0 differs from SGWO_STEER3');
fprintf('  nullOffset=0 BITWISE EQUAL\n');
s=base; s.nullOffset=900001; [B2,T2,i2]=SGWO_NULL(fc,s,[],N,seed+1000000);
assert(i2.Evaluations==budget && ~isequal(TF,T2),'offset != 0 must differ');
fprintf('  nullOffset=900001 ok FE=%d cost=%.6g (frozen %.6g)\n',i2.Evaluations,B2.Cost,BF.Cost);
fprintf('test_null_contract PASS.\n');
end
