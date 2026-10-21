function test_npar_contract()
%TEST_NPAR_CONTRACT  Audit bitwise equivalence and NPAR/random mode contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=5000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
% none and audit must be behaviourally bitwise equal to the frozen scaffold
s0=base; s0.nparMode='none'; s0.nparSeedOffset=222222;
sA=base; sA.nparMode='audit'; sA.nparSeedOffset=222222;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BN,TN]=SGWO_NPAR(fc,s0,[],N,seed+1000000);
[BD,TD,ia]=SGWO_NPAR(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TN) && isequal(TN,TD),'none/audit traces differ from scaffold');
assert(BA.Cost==BN.Cost && BN.Cost==BD.Cost,'none/audit Best differs');
assert(isequal(BA.Vector,BN.Vector) && isequal(BN.Vector,BD.Vector),'none/audit Vector differs');
assert(TD(end)==BD.Cost && ia.Evaluations==budget,'audit FE/Best contract failed');
fprintf('  audit ok FE=%d far=%d changed=%d eligible=%d fallback=%d\n', ...
    ia.Evaluations,ia.NparFarEvents,ia.NparChangedTarget,ia.NparEligibleEvents,ia.NparFallbackEvents);
% NPAR and random control must run with exact FE and archive accounting
for mode={'npar','random'}
    s=base; s.nparMode=mode{1}; s.nparSeedOffset=222222;
    [Bc,Tc,ic]=SGWO_NPAR(fc,s,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.NparActualReplacements<=ic.NparFarEvents,'actual replacements exceed far events');
    assert(ic.NparEligibleEvents<=ic.NparChangedTarget,'eligible exceeds changed-target events');
    fprintf('  %-6s ok FE=%d far=%d changed=%d eligible=%d actual=%d randomDiff=%d\n', ...
        mode{1},ic.Evaluations,ic.NparFarEvents,ic.NparChangedTarget, ...
        ic.NparEligibleEvents,ic.NparActualReplacements,ic.NparRandomDifferent);
end
fprintf('test_npar_contract PASS: none/audit bitwise; NPAR/random exact FE.\n');
end
