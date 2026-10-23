function test_nelshade_contract()
%TEST_NELSHADE_CONTRACT  Exact off path, FE accounting, and actuation checks.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=4001; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=LSHADE_CEC(fc,base,[],N,seed+1000000);
s=base; s.ecoMode='off';
[B0,T0,i0]=NELSHADE(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'NELSHADE off differs from LSHADE_CEC');
assert(i0.Evaluations==budget && numel(T0)==budget,'NELSHADE off FE or trace mismatch');
fprintf('  off             BITWISE EQUAL | FE=%d\n',i0.Evaluations);

modes={'random_adaptive','niche_fixed','niche_adaptive'};
for k=1:numel(modes)
    s=base; s.ecoMode=modes{k};
    [B,T,i]=NELSHADE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget && numel(T)==budget,'NELSHADE FE mismatch: %s',modes{k});
    assert(i.EcoNicheEval>0 && i.EcoNicheSrcGen>0,'niche channel did not actuate: %s',modes{k});
    if ~strcmp(modes{k},'random_adaptive')
        assert(i.EcoNicheBankSize>=4,'niche bank not populated: %s',modes{k});
    end
    assert(~isequal(TF,T),'mode produced identical trace: %s',modes{k});
    fprintf('  %-16s ok FE=%d bank=%d nicheEval=%d/%d p=%.3f best=%.6g\n', ...
        modes{k},i.Evaluations,i.EcoNicheBankSize,i.EcoNicheSuccess,i.EcoNicheEval,i.EcoPMean,B.Cost);
end
fprintf('test_nelshade_contract PASS.\n');
end
