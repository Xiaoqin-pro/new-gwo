function test_bgr_audit_contract()
%TEST_BGR_AUDIT_CONTRACT  BGR passive audit must be bitwise identical.
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
sA=base; sA.bgrMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BB,TB,ib]=SGWO_BGR(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TB),'BGR audit trace differs from frozen scaffold');
assert(BA.Cost==BB.Cost && isequal(BA.Vector,BB.Vector),'BGR audit Best differs');
assert(ib.Evaluations==budget,'BGR audit FE mismatch');
assert(ib.BgrOn==1 && ib.BgrG1Cand>0,'BGR audit counters missing');
fprintf('  audit ok FE=%d G1=%d outCand=%d outRate=%.4f outCoordRate=%.4f medClip=%.4g early/mid/late=%.3f/%.3f/%.3f\n', ...
    ib.Evaluations,ib.BgrG1Cand,ib.BgrOutCand,ib.BgrOutCandRate,ib.BgrOutCoordRate, ...
    ib.BgrClipDistMedian,ib.BgrEarlyRate,ib.BgrMidRate,ib.BgrLateRate);
fprintf('test_bgr_audit_contract PASS: passive BGR audit bitwise identical.\n');
end
