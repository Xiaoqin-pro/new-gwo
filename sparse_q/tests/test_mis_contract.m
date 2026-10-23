function test_mis_contract()
%TEST_MIS_CONTRACT  misIslands=1 must be bitwise identical to SGWO_STEER3; islands must act; migration must fire.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=4000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
 'misIslands',1,'misMigrateOn',1,'misMigrateEvery',100);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BM,TM,iM]=SGWO_MIS(fc,base,[],N,seed+1000000);
assert(isequal(TF,TM) && BF.Cost==BM.Cost,'MIS with 1 island differs from SGWO_STEER3');
fprintf('  misIslands=1  BITWISE EQUAL (best=%.6g)\n',BM.Cost);
for cfgv={ {2,1,'2 islands + migration'},{2,0,'2 islands no migration'},{5,1,'5 islands + migration'} }
    c=cfgv{1}; s=base; s.misIslands=c{1}; s.misMigrateOn=c{2};
    [B,T,i]=SGWO_MIS(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch: %s',c{3});
    fprintf('  %-24s ok FE=%d migrations=%d best=%.6g islandBests=%s\n',c{3},i.Evaluations,i.MisMigrations,B.Cost,mat2str(round(i.MisIslandBest,4)));
    if c{2}==1 && c{1}==2, assert(i.MisMigrations>0,'migration never fired'); end
end
fprintf('test_mis_contract PASS.\n');
end
