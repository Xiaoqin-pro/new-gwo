function test_vga_contract()
%TEST_VGA_CONTRACT  Standard equivalence and verified/random acceptance contract.
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
    s=b; s.vgaMode='none'; s.vgaSeedOffset=999999;
    [BA,TA]=SGWO_ABLATION(fc,b,[],N,seed+1000000);
    [BB,TB,ib]=SGWO_VGA(fc,s,[],N,seed+1000000);
    assert(isequal(TA,TB),'VGA none-state trace differs from ablation scaffold');
    assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'VGA none-state Best differs');
    assert(ib.Evaluations==budget,'VGA none-state FE mismatch');
    fprintf('  none/g2off=%d ok FE=%d cost=%.6g\n',g2off,ib.Evaluations,BB.Cost);
end
for mode={'verified','random'}
    b=base; b.ablateG2=1; b.ablateE=0;
    b.vgaMode=mode{1}; b.vgaSeedOffset=999999;
    [Bc,Tc,ic]=SGWO_VGA(fc,b,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(ic.VGAOn==1,'VGA flag not set');
    assert(ic.VGAEvalCount>0,'no VGA G1 evaluation recorded');
    assert(ic.VGAAcceptCount>=0 && ic.VGAAcceptCount<=ic.VGAEvalCount,'invalid VGA acceptance count');
    if strcmp(mode{1},'verified')
        assert(ic.VGAAcceptCount==ic.VGASuccCount,'verified acceptance must equal verified improvements');
    end
    fprintf('  %-8s ok FE=%d eval=%d succ=%d accept=%d rate=%.4f pR=%.4f\n', ...
        mode{1},ic.Evaluations,ic.VGAEvalCount,ic.VGASuccCount,ic.VGAAcceptCount, ...
        ic.VGAAcceptRate,ic.VGAPReplaceMean);
end
fprintf('test_vga_contract PASS: none-state bitwise for G2-off/on; VGA modes exact FE.\n');
end
