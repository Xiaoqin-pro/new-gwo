function test_vacg_contract()
%TEST_VACG_CONTRACT  Off-state bitwise equivalence and VACG candidate contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3991;
rng(261013000+7*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,7);
% off-state must be bitwise identical to frozen SGWO
off=base; off.vacgOn=0; off.vacgMode='mad';
[BA,TA]=SGWO(fc,base,[],N,seed+1000000);
[BO,TO,io]=SGWO_VACG(fc,off,[],N,seed+1000000);
assert(isequal(TA,TO),'VACG off-state trace differs from frozen SGWO');
assert(BA.Cost==BO.Cost && isequal(BA.Vector,BO.Vector),'VACG off-state Best differs');
assert(io.Evaluations==budget,'VACG off-state FE mismatch');
% MAD arm
mad=base; mad.vacgOn=1; mad.vacgMode='mad'; mad.vacgTopFrac=0.25; mad.vacgNoise=0.25; mad.vacgMinArc=3;
[Bm,Tm,im]=SGWO_VACG(fc,mad,[],N,seed+1000000);
assert(im.Evaluations==budget && all(diff(Tm)<=0),'VACG MAD run broken');
assert(im.VACGGenCount>0,'MAD generated no grafting candidates');
assert(im.VACGEvalCount>0,'MAD grafting candidates never evaluated');
assert(im.VACGLowFrac>0.40 && im.VACGLowFrac<0.60,'MAD low-coordinate fraction out of range');
assert(isfinite(im.VACGCstarMeanRank),'MAD parent rank missing');
% RandomSplit arm
rnd=mad; rnd.vacgMode='random';
[Br,Tr,ir]=SGWO_VACG(fc,rnd,[],N,seed+1000000);
assert(ir.Evaluations==budget && all(diff(Tr)<=0),'VACG RandomSplit run broken');
assert(ir.VACGGenCount>0 && ir.VACGEvalCount>0,'RandomSplit grafting never used');
assert(ir.VACGLowFrac>0.40 && ir.VACGLowFrac<0.60,'RandomSplit low-coordinate fraction out of range');
fprintf('test_vacg_contract PASS: off bitwise; MAD gen=%d eval=%d succ=%.3f low=%.3f; RND gen=%d low=%.3f\n', ...
    im.VACGGenCount,im.VACGEvalCount,im.VACGSuccessRate,im.VACGLowFrac,ir.VACGGenCount,ir.VACGLowFrac);
end
