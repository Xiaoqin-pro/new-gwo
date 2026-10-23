function test_emix_contract()
%TEST_EMIX_CONTRACT  eShellShare=0.5 must be bitwise identical to SGWO_STEER3; other shares must act.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5,'eShellShare',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BM,TM,iM]=SGWO_EMIX(fc,base,[],N,seed+1000000);
assert(isequal(TF,TM) && BF.Cost==BM.Cost,'EMIX 0.5 differs from SGWO_STEER3');
fprintf('  eShellShare=0.50 BITWISE EQUAL (shell per=%d)\n',iM.EShellPer);
for sh=[0.25 0.0 0.75]
    s=base; s.eShellShare=sh;
    [B,T,i]=SGWO_EMIX(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch at share %.2f',sh);
    assert(~isequal(TF,T),'share %.2f produced an identical trace',sh);
    fprintf('  eShellShare=%.2f ok FE=%d per=%d cost=%.6g\n',sh,i.Evaluations,i.EShellPer,B.Cost);
end
fprintf('test_emix_contract PASS.\n');
end
