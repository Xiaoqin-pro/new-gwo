function test_aslshade_contract()
%TEST_ASLSHADE_CONTRACT  Dense exactness and K-scheduler actuation.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4007; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget,'screenMode','dense');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=LSHADE_CEC(fc,base,[],N,seed+1000000);
[B0,T0,i0]=ASLSHADE(fc,base,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'ASLSHADE dense differs from LSHADE_CEC');
assert(i0.Evaluations==budget && numel(T0)==budget,'dense FE/trace mismatch');
fprintf('  dense       BITWISE EQUAL | FE=%d\n',i0.Evaluations);
for m={'fixedK','randomK','adaptiveK','stagnationK'}
    s=base; s.screenMode=m{1}; s.sparseK=10; s.kChoices=[10 25 50]; s.kWindowFrac=0.10;
    [B,T,i]=ASLSHADE(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget && numel(T)==budget,'FE mismatch: %s',m{1});
    if ~strcmp(m{1},'fixedK'), assert(sum(i.KCounts)>0,'scheduler did not actuate: %s',m{1}); end
    if ~strcmp(m{1},'fixedK'), assert(size(i.KTrace,1)>=2,'K trace too short: %s',m{1}); end
    fprintf('  %-9s ok FE=%d gen=%d Kcounts=%s best=%.6g\n', ...
        m{1},i.Evaluations,i.Rounds,mat2str(i.KCounts),B.Cost);
end
fprintf('test_aslshade_contract PASS.\n');
end
