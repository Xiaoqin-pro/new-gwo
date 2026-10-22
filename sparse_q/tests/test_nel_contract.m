function test_nel_contract()
%TEST_NEL_CONTRACT  Standard equivalence and NEL mode contract.
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
s0=base; s0.nelMode='none';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BN,TN,i0]=SGWO_NEL(fc,s0,[],N,seed+1000000);
assert(isequal(TA,TN),'NEL none trace differs from ablation scaffold');
assert(BA.Cost==BN.Cost && isequal(BA.Vector,BN.Vector),'NEL none Best differs');
assert(i0.Evaluations==budget,'NEL none FE mismatch');
for mode={'on','random'}
    s=base; s.nelMode=mode{1}; s.nelNeighbors=10; s.nelPc=0.5; s.nelPert=0.1; s.nelSeedOffset=555555;
    [B,T,inf1]=SGWO_NEL(fc,s,[],N,seed+1000000);
    assert(inf1.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',mode{1}));
    assert(inf1.NelCandidates>0,'no NEL candidate generated');
    fprintf('  %-6s ok FE=%d candidates=%d selected=%d cost=%.6g\n',mode{1}, ...
        inf1.Evaluations,inf1.NelCandidates,inf1.NelSelected,B.Cost);
end
fprintf('test_nel_contract PASS: NEL none bitwise; on/random exact FE.\n');
end
