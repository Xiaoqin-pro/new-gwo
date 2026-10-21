function test_enac_contract()
%TEST_ENAC_CONTRACT  Frozen bitwise equivalence and ENAC arm contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3989;
rng(261013000+7*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,7);
% frozen path must be bitwise identical
off=base; off.enacOn=0;
[BA,TA]=SGWO(fc,base,[],N,seed+1000000);
[BO,TO,io]=SGWO_ENAC(fc,off,[],N,seed+1000000);
assert(isequal(TA,TO),'ENAC off-state trace differs from frozen SGWO');
assert(BA.Cost==BO.Cost && isequal(BA.Vector,BO.Vector),'ENAC off-state Best differs');
assert(io.Evaluations==budget,'ENAC off-state FE mismatch');
% identity arm
idc=base; idc.enacOn=1; idc.enacMode='identity'; idc.enacA=1; idc.enacB=1;
[Bi,Ti,ii]=SGWO_ENAC(fc,idc,[],N,seed+1000000);
assert(ii.Evaluations==budget && all(diff(Ti)<=0),'Identity-Credit run broken');
assert(ii.EnacCenterEvalTotal>0 && ii.EnacCenterSuccTotal>0,'identity centre stats missing');
assert(isfinite(ii.EnacMeanTopRatio) && ii.EnacMeanTopRatio>0,'identity top ratio missing');
% ENAC arm
ena=idc; ena.enacMode='enac';
[Be,Te,ie]=SGWO_ENAC(fc,ena,[],N,seed+1000000);
assert(ie.Evaluations==budget && all(diff(Te)<=0),'ENAC run broken');
assert(ie.EnacCenterEvalTotal>0 && ie.EnacCenterSuccTotal>0,'ENAC centre stats missing');
assert(isfinite(ie.EnacMeanTopRatio) && isfinite(ie.EnacMeanWeightEntropy),'ENAC weight trace missing');
assert(ie.EnacDroppedFeedback>=0,'negative dropped feedback');
fprintf('test_enac_contract PASS: off bitwise; identityRatio=%.3f enacRatio=%.3f dropped=%d sucessEval=%d/%d\n', ...
    ii.EnacMeanTopRatio,ie.EnacMeanTopRatio,ie.EnacDroppedFeedback,ie.EnacCenterSuccTotal,ie.EnacCenterEvalTotal);
end
