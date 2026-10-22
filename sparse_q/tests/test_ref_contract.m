function test_ref_contract()
%TEST_REF_CONTRACT  Standard equivalence and REF/uniform contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
s0=base; s0.refMode='none';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BR,TR,i0]=SGWO_REF(fc,s0,[],N,seed+1000000);
assert(isequal(TA,TR),'REF none trace differs from ablation scaffold');
assert(BA.Cost==BR.Cost && isequal(BA.Vector,BR.Vector),'REF none Best differs');
assert(i0.Evaluations==budget,'REF none FE mismatch');
for mode={'ref','uniform'}
    s=base; s.refMode=mode{1}; s.refSeedOffset=666666;
    [B,T,inf1]=SGWO_REF(fc,s,[],N,seed+1000000);
    assert(inf1.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',mode{1}));
    assert(inf1.RefCandidates>0,'no REF candidate generated');
    fprintf('  %-7s ok FE=%d candidates=%d selected=%d cost=%.6g\n',mode{1}, ...
        inf1.Evaluations,inf1.RefCandidates,inf1.RefSelected,B.Cost);
end
fprintf('test_ref_contract PASS: REF none bitwise; ref/uniform exact FE.\n');
end
