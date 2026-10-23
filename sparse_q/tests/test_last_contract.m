function test_last_contract()
%TEST_LAST_CONTRACT  All-off bitwise identical; obl/lhs/coverage all act.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
 'initMode','runner','centreCoverage',0);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BO,TO,iO]=SGWO_LAST(fc,base,[],N,seed+1000000);
assert(isequal(TF,TO) && BF.Cost==BO.Cost,'all-off differs from SGWO_STEER3');
fprintf('  all-off BITWISE EQUAL\n');
for c={ {'obl',0,'obl init'},{'lhs',0,'lhs init'},{'runner',1,'centre coverage'} }
    s=base; s.initMode=c{1}{1}; s.centreCoverage=c{1}{2};
    [B,T,i]=SGWO_LAST(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',c{1}{3});
    assert(~isequal(TF,T),'%s produced identical trace',c{1}{3});
    fprintf('  %-16s ok FE=%d cost=%.6g\n',c{1}{3},i.Evaluations,B.Cost);
end
fprintf('test_last_contract PASS.\n');
end
