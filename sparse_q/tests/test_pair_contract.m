function test_pair_contract()
%TEST_PAIR_CONTRACT  none/audit bitwise identical to SGWO_STEER3; quality/shuffled act; audit fills bins.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=4000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
 'pairMode','none');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
for m={'none','audit'}
    s=base; s.pairMode=m{1};
    [B,T,i]=SGWO_PAIR(fc,s,[],N,seed+1000000);
    assert(isequal(TF,T) && BF.Cost==B.Cost,'%s differs from SGWO_STEER3',m{1});
    fprintf('  %-6s BITWISE EQUAL | pairN=%d bins=[%d %d %d]\n',m{1},i.PairN,i.PairEvalC);
    if strcmp(m{1},'audit'), assert(i.PairN>0,'audit logged no pair evaluations'); end
end
for m={'quality','shuffled'}
    s=base; s.pairMode=m{1};
    [B,T,i]=SGWO_PAIR(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',m{1});
    assert(~isequal(TF,T),'%s produced identical trace',m{1});
    fprintf('  %-9s ok FE=%d cost=%.6g\n',m{1},i.Evaluations,B.Cost);
end
fprintf('test_pair_contract PASS.\n');
end
