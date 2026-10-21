function test_cala_contract()
%TEST_CALA_CONTRACT  Standard equivalence, CALA and RandomLeader contract.
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
% standard two-route must match ablation scaffold with same state
s0=base; s0.calaMode='none'; s0.calaEps=1e-12; s0.calaSeedOffset=666666;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BB,TB,ib]=SGWO_CALA(fc,s0,[],N,seed+1000000);
assert(isequal(TA,TB),'CALA none-state trace differs from ablation scaffold');
assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'CALA none-state Best differs');
assert(ib.Evaluations==budget,'CALA none-state FE mismatch');
% CALA and RandomLeader modes
for mode={'cala','random'}
    s=base; s.calaMode=mode{1}; s.calaEps=1e-12; s.calaSeedOffset=666666;
    [Bc,Tc,ic]=SGWO_CALA(fc,s,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.CALAUseCount>0,'no CALA use recorded');
    assert(ic.CALARhoMean>=0 && ic.CALARhoMean<=1,'rho mean outside [0,1]');
    assert(ic.CALARhoMax>=0 && ic.CALARhoMax<=1,'rho max outside [0,1]');
    if strcmp(mode{1},'random'), assert(ic.CALARandomLeaderCount>0,'random leader never drawn'); end
    fprintf('  %-8s ok FE=%d rhoMean=%.4f rhoMax=%.4f use=%d random=%d\n', ...
        mode{1},ic.Evaluations,ic.CALARhoMean,ic.CALARhoMax,ic.CALAUseCount,ic.CALARandomLeaderCount);
end
fprintf('test_cala_contract PASS: two-route standard bitwise; CALA modes run.\n');
end
