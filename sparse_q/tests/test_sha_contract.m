function test_sha_contract()
%TEST_SHA_CONTRACT  linear is bitwise equal to SGWO_STEER3; history/placebo actuate.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3988; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.shaMode='linear';
[B0,T0,i0]=SGWO_SHA(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'linear differs from SGWO_STEER3');
fprintf('  linear  BITWISE EQUAL | FE=%d trace=%d\n',i0.Evaluations,size(i0.ShaTrace,1));
for m={'history','placebo'}
    s=base; s.shaMode=m{1};
    [B,T,i]=SGWO_SHA(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    assert(~isempty(i.ShaTrace),'%s did not record SHA trace',m{1});
    assert(i.ShaEvals>0,'%s did not update SHA',m{1});
    fprintf('  %-7s ok FE=%d G1eval=%d G1succ=%d cost=%.6g\n',m{1},i.Evaluations,i.ShaEvals,i.ShaSuccess,B.Cost);
end
fprintf('test_sha_contract PASS.\n');
end
