function test_slshade_contract()
%TEST_SLSHADE_CONTRACT  Dense equivalence and sparse FE accounting.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4005; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget,'screenPolicy','dense');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=LSHADE_CEC(fc,base,[],N,seed+1000000);
[B0,T0,i0]=SLSHADE(fc,base,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'SLSHADE dense differs from LSHADE_CEC');
assert(i0.Evaluations==budget && numel(T0)==budget,'dense FE/trace mismatch');
fprintf('  dense       BITWISE EQUAL | FE=%d\n',i0.Evaluations);
for m={'random','near','dual'}
    s=base; s.screenPolicy=m{1}; s.sparseK=10;
    [B,T,i]=SLSHADE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget && numel(T)==budget,'FE mismatch: %s',m{1});
    assert(i.TrialsSelected<i.TrialsGenerated,'not sparse: %s',m{1});
    assert(~isequal(TF,T),'sparse trace identical: %s',m{1});
    if strcmp(m{1},'dual'), assert(i.NearSelected>0 && i.FarSelected>0,'dual screen not actuated'); end
    fprintf('  %-7s ok FE=%d gen=%d selected=%d/%d near=%d far=%d best=%.6g\n', ...
        m{1},i.Evaluations,i.Rounds,i.TrialsSelected,i.TrialsGenerated,i.NearSelected,i.FarSelected,B.Cost);
end
fprintf('test_slshade_contract PASS.\n');
end
