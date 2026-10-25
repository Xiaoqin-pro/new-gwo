function test_ghs_contract()
%TEST_GHS_CONTRACT  off is bitwise equal; GH-SHADE subpopulation actuates.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3995; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.hybMode='off';
[B0,T0,i0]=SGWO_GHS(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'off differs from SGWO_STEER3');
fprintf('  off   BITWISE EQUAL | FE=%d\n',i0.Evaluations);
s=base; s.hybMode='shade'; s.hybN=20;
[B,T,i]=SGWO_GHS(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget,'FE mismatch shade');
assert(~isequal(TF,T),'shade produced identical trace');
assert(i.ShadeApplied>0,'GH-SHADE did not apply');
fprintf('  shade ok FE=%d applied=%d success=%d archive=%d cost=%.6g\n',i.Evaluations,i.ShadeApplied,i.ShadeSuccess,i.ShadeArchiveSize,B.Cost);
fprintf('test_ghs_contract PASS.\n');
end
