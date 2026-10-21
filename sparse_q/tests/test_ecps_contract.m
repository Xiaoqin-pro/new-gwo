function test_ecps_contract()
%TEST_ECPS_CONTRACT  Standard equivalence, ECPS mode contract, and FE discipline.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986;
rng(261013000+1*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',0,'nE',50,'screenPolicy','random');
fc=@(x)CEC2017Function(x,1);
s0=base; s0.ecpsMode='none'; s0.ecpsWindow=1000; s0.ecpsSeedOffset=777777;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BB,TB,ib]=SGWO_ECPS(fc,s0,[],N,seed+1000000);
assert(isequal(TA,TB),'ECPS none-state trace differs from ablation scaffold');
assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'ECPS none-state Best differs');
assert(ib.Evaluations==budget,'ECPS none-state FE mismatch');
for mode={'ecps','random'}
    s=base; s.ecpsMode=mode{1}; s.ecpsWindow=1000; s.ecpsSeedOffset=777777;
    [Bc,Tc,ic]=SGWO_ECPS(fc,s,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.ECPSOn==1,'ECPS flag not set');
    assert(sum(ic.ECPSActionCounts)>0,'no ECPS action recorded');
    assert(sum(ic.ECPSEvalCounts)>0,'no ECPS evaluated candidate recorded');
    fprintf('  %-8s ok FE=%d actions=%s eval=%s succ=%s entropy=%.4f\n', ...
        mode{1},ic.Evaluations,mat2str(ic.ECPSActionCounts), ...
        mat2str(ic.ECPSEvalCounts),mat2str(ic.ECPSSuccCounts),ic.ECPSEntropyMean);
end
fprintf('test_ecps_contract PASS: none-state bitwise; ECPS modes run with exact FE.\n');
end
