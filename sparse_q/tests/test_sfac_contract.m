function test_sfac_contract()
%TEST_SFAC_CONTRACT  Off-state bitwise equivalence and SFAC feedback contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3993;
rng(261013000+7*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,7);
% off-state must be bitwise identical to frozen SGWO
off=base; off.sfacOn=0; off.sfacUniform=0;
[BA,TA]=SGWO(fc,base,[],N,seed+1000000);
[BO,TO,io]=SGWO_SFAC(fc,off,[],N,seed+1000000);
assert(isequal(TA,TO),'SFAC off-state trace differs from frozen SGWO');
assert(BA.Cost==BO.Cost && isequal(BA.Vector,BO.Vector),'SFAC off-state Best differs');
assert(io.Evaluations==budget,'SFAC off-state FE mismatch');
% on-state must record real successes, failures and bounded credit
on=base; on.sfacOn=1; on.sfacUniform=0; on.sfacDecay=1; on.sfacFloor=0;
[Bn,Tn,inn]=SGWO_SFAC(fc,on,[],N,seed+1000000);
assert(inn.Evaluations==budget,'SFAC on-state FE mismatch');
assert(all(diff(Tn)<=0) && abs(Tn(end)-Bn.Cost)<=1e-9*max(1,abs(Bn.Cost)),'SFAC on trace broken');
assert(inn.ArcGenCountTotal>0,'no archive generation recorded');
assert(inn.ArcEvalCountTotal>0,'no archive evaluation recorded');
assert(inn.SFACBoostCount>0,'no success credit recorded');
assert(inn.SFACDecayCount>0,'no failure decrement recorded');
assert(inn.ArcCredZeroFrac>=0 && inn.ArcCredZeroFrac<=1,'credit zero fraction out of range');
assert(inn.ArcCredSum>=0,'negative credit sum');
% uniform control is a valid arm (still updates credit, no weight use)
un=on; un.sfacUniform=1;
[Bu,Tu,iu]=SGWO_SFAC(fc,un,[],N,seed+1000000);
assert(iu.Evaluations==budget && iu.SFACUniform==1,'uniform control FE/flag mismatch');
fprintf('test_sfac_contract PASS: off bitwise; on boost=%d decay=%d zeroFrac=%.3f genTop=%.3f evalTop=%.3f success=%.3f\n', ...
    inn.SFACBoostCount,inn.SFACDecayCount,inn.ArcCredZeroFrac,inn.ArcGenTopShare,inn.ArcEvalTopShare,inn.ArcEvalSuccessRate);
end
