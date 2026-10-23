function test_nmlshade_contract()
%TEST_NMLSHADE_CONTRACT  Off equivalence and zero-FE niche migration.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4003; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=LSHADE_CEC(fc,base,[],N,seed+1000000);
s=base; s.migMode='off';
[B0,T0,i0]=NMLSHADE(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'NMLSHADE off differs from LSHADE_CEC');
assert(i0.Evaluations==budget && numel(T0)==budget,'NMLSHADE off FE/trace mismatch');
fprintf('  off             BITWISE EQUAL | FE=%d\n',i0.Evaluations);

modes={'periodic_niche','plateau_random','plateau_niche'};
for k=1:numel(modes)
    s=base; s.migMode=modes{k};
    [B,T,i]=NMLSHADE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget && numel(T)==budget,'FE mismatch: %s',modes{k});
    assert(i.MigTriggers>0,'no migration trigger: %s',modes{k});
    assert(i.MigMigrants>0,'no migrants: %s',modes{k});
    if ~strcmp(modes{k},'plateau_random')
        assert(i.MigBankSize>=4,'niche bank not populated: %s',modes{k});
    end
    fprintf('  %-16s ok FE=%d trig=%d mig=%d bank=%d hist=%d best=%.6g\n', ...
        modes{k},i.Evaluations,i.MigTriggers,i.MigMigrants,i.MigBankSize,i.MigHistSize,B.Cost);
end
fprintf('test_nmlshade_contract PASS.\n');
end
