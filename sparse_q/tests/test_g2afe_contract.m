function test_g2afe_contract()
%TEST_G2AFE_CONTRACT  Unit contract for SGWO_AFE and its matched control.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+3*10000+3995,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
afe=base; afe.g2AFEAlways=0; afe.g2AFERandomDir=0;
afe.g2AFETriggerFrac=0.05; afe.g2AFEMinArc=4; afe.g2AFEMinPairFrac=0.005;
afe.g2AFELambdaMin=0.25; afe.g2AFELambdaMax=0.75; afe.g2AFEEpsFrac=0.05;
s=st; fn=fieldnames(afe); for k=1:numel(fn), s.(fn{k})=afe.(fn{k}); end
fc=@(x)CEC2017Function(x,3);
[Ba,Ta,ia]=SGWO_AFE(fc,s,[],N,3995+1000000);
assert(ia.Evaluations==budget,'FE mismatch');
assert(all(diff(Ta)<=0) && abs(Ta(end)-Ba.Cost)<=1e-9*max(1,abs(Ba.Cost)),'trace broken');
assert(ia.G2AFEActiveRounds>0,'trigger never activated');
assert(ia.G2AFECandidates>0,'no AFE candidate generated');
assert(ia.G2AFEFallbackCandidates>=0,'negative fallback count');
assert(ia.G2EvalCount==ia.EvalCnt(2),'G2 evaluation counter mismatch');
assert(isfinite(ia.G2AFEStepMean) && ia.G2AFEStepMean>0,'bad AFE step mean');
assert(ia.G2AFEMinPairFrac==afe.g2AFEMinPairFrac,'pair threshold not preserved');

% Random-direction control must have the same trigger and mechanism hooks.
s2=s; s2.g2AFERandomDir=1;
[Br,Tr,ir]=SGWO_AFE(fc,s2,[],N,3995+1000000);
assert(ir.Evaluations==budget && abs(Tr(end)-Br.Cost)<=1e-9*max(1,abs(Br.Cost)),'random-dir trace broken');
assert(ir.G2AFEActiveRounds>0 && ir.G2AFECandidates>0,'random-dir AFE inactive');
assert(ir.G2AFERandomDir==1,'random-dir flag not recorded');

% Base SGWO_ABLATION must remain bitwise equal to frozen SGWO.
[BA,TA]=SGWO(fc,st,[],N,3995+1000000);
[BB,TB,ib]=SGWO_ABLATION(fc,st,[],N,3995+1000000);
assert(isequal(TA,TB) && BA.Cost==BB.Cost,'instrumentation changed base trace');
assert(ib.Evaluations==budget && sum(ib.EvalCnt)>0,'base instrumentation broken');
fprintf('test_g2afe_contract PASS: AFE eval=%d, activeRounds=%d, pairValid=%d, stepMean=%.4g\n', ...
    ia.G2EvalCount,ia.G2AFEActiveRounds,ia.G2AFEPairValidRounds,ia.G2AFEStepMean);
end
