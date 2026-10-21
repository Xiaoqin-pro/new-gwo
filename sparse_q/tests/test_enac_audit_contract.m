function test_enac_audit_contract()
%TEST_ENAC_AUDIT_CONTRACT  Audit must be bitwise identical to frozen SGWO.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3989;
rng(261013000+7*10000+seed,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,7);
[BA,TA]=SGWO(fc,st,[],N,seed+1000000);
aud=st; aud.auditOn=1;
[BB,TB,ib]=SGWO_ENAC_AUDIT(fc,aud,[],N,seed+1000000);
assert(isequal(TA,TB),'ENAC audit changed the frozen trace');
assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'ENAC audit changed Best');
assert(ib.Evaluations==budget,'ENAC audit FE mismatch');
assert(ib.AuditEvalWithParent>0,'no parent-evaluated candidates recorded');
assert(ib.AuditNearRepl+ib.AuditFarRepl>0,'no archive replacements observed');
assert(ib.AuditESuccessUpdates>0,'no E success updates observed');
assert(isfinite(ib.AuditMeanTopRatio) && ib.AuditMeanTopRatio>0,'bad top-ratio trace');
assert(ib.AuditMeanWeightEntropy>=0 && ib.AuditMeanWeightEntropy<=1,'bad weight entropy');
fprintf('test_enac_audit_contract PASS: bitwise; Eeval=%d stale=%d slot=%d wrong=%d near=%d leak=%d topRatio=%.3f entropy=%.3f spearman=%.3f\n', ...
    ib.AuditEvalWithParent,ib.AuditStaleEvents,ib.AuditSlotReassigned,ib.AuditWrongUpdate, ...
    ib.AuditNearRepl,ib.AuditLeakTotal,ib.AuditMeanTopRatio,ib.AuditMeanWeightEntropy,ib.AuditSpearmanCreditPhat);
end
