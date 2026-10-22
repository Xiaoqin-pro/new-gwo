function test_vssm_audit_contract()
%TEST_VSSM_AUDIT_CONTRACT  VSSM audit must be bitwise identical; on must run exact FE.
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
sA=base; sA.vssmMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BV,TV,iv]=SGWO_VSSM(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TV),'VSSM audit trace differs from frozen scaffold');
assert(BA.Cost==BV.Cost && isequal(BA.Vector,BV.Vector),'VSSM audit Best differs');
assert(iv.Evaluations==budget,'VSSM audit FE mismatch');
assert(iv.VssmG1Eval>0,'VSSM audit did not see G1 evaluations');
assert(iv.VssmSuccess>0,'VSSM audit saw no successes');
assert(size(iv.VssmTrace,1)>0 && size(iv.VssmTrace,2)==8,'VSSM trace missing');
fprintf('  audit ok FE=%d G1eval=%d success=%d rate=%.4f successesR_med=%.4g IQR=%.4g eligible=%d dev10=%.4f boundary=%.4f fallback=%d\n', ...
    iv.Evaluations,iv.VssmG1Eval,iv.VssmSuccess,iv.VssmSuccessRate,iv.VssmMedianSuccessR, ...
    iv.VssmIQRSuccessR,iv.VssmEligibleUpdates,iv.VssmRhoDev10Rate,iv.VssmBoundaryRate,iv.VssmFallbackUpdates);
sOn=base; sOn.vssmMode='on';
[BO,TO,io]=SGWO_VSSM(fc,sOn,[],N,seed+1000000);
assert(io.Evaluations==budget && all(diff(TO)<=0),'VSSM on run broken');
fprintf('  on    ok FE=%d cost=%.6g differs=%d\n',io.Evaluations,BO.Cost,~isequal(TO,TA));
fprintf('test_vssm_audit_contract PASS: audit bitwise identical; VSSM-on exact FE.\n');
end
