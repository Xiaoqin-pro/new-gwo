function test_trps_contract()
%TEST_TRPS_CONTRACT  Standard equivalence, TRPS modes, and G2-off/on contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986;
rng(261013000+1*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,1);
for g2off=[1 0]
    b=base; b.ablateG2=g2off; b.ablateE=0;
    s=b; s.trpsMode='none'; s.trpsWindow=1000; s.trpsSeedOffset=888888;
    [BA,TA]=SGWO_ABLATION(fc,b,[],N,seed+1000000);
    [BB,TB,ib]=SGWO_TRPS(fc,s,[],N,seed+1000000);
    assert(isequal(TA,TB),'TRPS none-state trace differs from ablation scaffold');
    assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'TRPS none-state Best differs');
    assert(ib.Evaluations==budget,'TRPS none-state FE mismatch');
    fprintf('  none/g2off=%d ok FE=%d cost=%.6g\n',g2off,ib.Evaluations,BB.Cost);
end
for mode={'trps','random'}
    b=base; b.ablateG2=1; b.ablateE=0;
    b.trpsMode=mode{1}; b.trpsWindow=1000; b.trpsSeedOffset=888888;
    [Bc,Tc,ic]=SGWO_TRPS(fc,b,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.ECPSOn==1,'TRPS flag not set');
    assert(sum(ic.ECPSActionCounts)>0,'no TRPS action recorded');
    assert(sum(ic.ECPSEvalCounts)>0,'no TRPS evaluated candidate recorded');
    fprintf('  %-6s ok FE=%d actions=%s eval=%s succ=%s entropy=%.4f\n', ...
        mode{1},ic.Evaluations,mat2str(ic.ECPSActionCounts), ...
        mat2str(ic.ECPSEvalCounts),mat2str(ic.ECPSSuccCounts),ic.ECPSEntropyMean);
end
fprintf('test_trps_contract PASS: none-state bitwise for G2-off/on; TRPS modes exact FE.\n');
end
