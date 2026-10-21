function test_cagl_contract()
%TEST_CAGL_CONTRACT  Audit bitwise equivalence and CAGL/random mode contract.
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
s0=base; s0.caglMode='none'; s0.caglSeedOffset=333333;
sA=base; sA.caglMode='audit'; sA.caglSeedOffset=333333;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BN,TN]=SGWO_CAGL(fc,s0,[],N,seed+1000000);
[BD,TD,ia]=SGWO_CAGL(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TN) && isequal(TN,TD),'none/audit traces differ from scaffold');
assert(BA.Cost==BN.Cost && BN.Cost==BD.Cost,'none/audit Best differs');
assert(isequal(BA.Vector,BN.Vector) && isequal(BN.Vector,BD.Vector),'none/audit Vector differs');
assert(TD(end)==BD.Cost && ia.Evaluations==budget,'audit FE/Best contract failed');
fprintf('  audit ok FE=%d rounds=%d collapse=%d eligibleRounds=%d dirEvents=%d meanCos=%.4f\n', ...
    ia.Evaluations,ia.CaglRounds,ia.CaglCollapseRounds,ia.CaglEligibleRounds, ...
    ia.CaglDirectionEvents,ia.CaglMeanCos);
for mode={'cagl','random'}
    s=base; s.caglMode=mode{1}; s.caglSeedOffset=333333;
    [Bc,Tc,ic]=SGWO_CAGL(fc,s,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.CaglGuidedCandidates<=ic.CaglDirectionEvents,'guided candidates exceed direction events');
    if strcmp(mode{1},'random'), assert(ic.CaglRandomSelections>=0,'random counter invalid'); end
    fprintf('  %-6s ok FE=%d collapse=%d eligible=%d guided=%d dirEvents=%d meanCos=%.4f randomSel=%d\n', ...
        mode{1},ic.Evaluations,ic.CaglCollapseRounds,ic.CaglEligibleRounds, ...
        ic.CaglGuidedCandidates,ic.CaglDirectionEvents,ic.CaglMeanCos,ic.CaglRandomSelections);
end
fprintf('test_cagl_contract PASS: none/audit bitwise; CAGL/random exact FE.\n');
end
