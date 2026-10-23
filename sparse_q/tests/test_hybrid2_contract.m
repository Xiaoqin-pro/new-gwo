function test_hybrid2_contract()
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3998; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'hybFrac',0.5);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=SGWO_HYBRID2(fc,base,[],N,seed+1000000);
assert(i.Evaluations==budget); assert(numel(T)==budget); assert(i.Stage1FE==3000 && i.Stage2FE==3000);
fprintf('hybrid2 ok FE=%d stage1=%d stage2=%d best=%.6g\n',i.Evaluations,i.Stage1FE,i.Stage2FE,B.Cost);
fprintf('test_hybrid2_contract PASS.\n');
end
