function test_sssa_contract()
%TEST_SSSA_CONTRACT  Off-state bitwise equivalence and source-scale contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3990;
rng(261013000+7*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,7);
% off-state must be bitwise identical to frozen SGWO
off=base; off.sssaOn=0; off.sssaSwap=0;
[BA,TA]=SGWO(fc,base,[],N,seed+1000000);
[BO,TO,io]=SGWO_SSSA(fc,off,[],N,seed+1000000);
assert(isequal(TA,TO),'SSSA off-state trace differs from frozen SGWO');
assert(BA.Cost==BO.Cost && isequal(BA.Vector,BO.Vector),'SSSA off-state Best differs');
assert(io.Evaluations==budget,'SSSA off-state FE mismatch');
% source-matched arm
on=base; on.sssaOn=1; on.sssaSwap=0; on.sssaCap=25; on.sssaMin=5; on.sssaInitFrac=0.05; on.sssaFloorFrac=0.01;
[Bn,Tn,inn]=SGWO_SSSA(fc,on,[],N,seed+1000000);
assert(inn.Evaluations==budget && all(diff(Tn)<=0),'SSSA arm broken');
assert(isfinite(inn.SigmaG2Mean) && inn.SigmaG2Mean>0,'bad sigma G2');
assert(isfinite(inn.SigmaEMean) && inn.SigmaEMean>0,'bad sigma E');
assert(inn.G2SuccessHistoryN>0,'no G2 success history');
assert(inn.E1SuccessHistoryN>0,'no E single-centre success history');
assert(inn.G2SuccessCount>0 && inn.E1SuccessCount>0,'no source success events');
assert(inn.G2SuccessRate>=0 && inn.G2SuccessRate<=1,'bad G2 success rate');
assert(inn.E1SuccessRate>=0 && inn.E1SuccessRate<=1,'bad E success rate');
% swapped-source control
sw=on; sw.sssaSwap=1;
[Bs,Ts,is]=SGWO_SSSA(fc,sw,[],N,seed+1000000);
assert(is.Evaluations==budget && all(diff(Ts)<=0),'SSSA-Swap arm broken');
assert(is.SSSASwap==1,'swap flag missing');
assert(isfinite(is.SigmaG2Mean) && isfinite(is.SigmaEMean),'swap sigma missing');
fprintf('test_sssa_contract PASS: off bitwise; sigmaG2=%.4g sigmaE=%.4g ratio=%.4g g2succ=%d esucc=%d\n', ...
    inn.SigmaG2End,inn.SigmaEEnd,inn.SigmaRatioMean,inn.G2SuccessCount,inn.E1SuccessCount);
end
