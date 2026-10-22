function test_tsdr_audit_contract()
%TEST_TSDR_AUDIT_CONTRACT  TSD-R shadow audit must be bitwise identical.
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
sA=base; sA.tsdrMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BR,TR,ir]=SGWO_TSDR(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TR),'TSD-R audit trace differs from frozen scaffold');
assert(BA.Cost==BR.Cost && isequal(BA.Vector,BR.Vector),'TSD-R audit Best differs');
assert(ir.Evaluations==budget,'TSD-R audit FE mismatch');
assert(ir.TsdrG1Eval>0 && size(ir.TsdrTrace,2)==9,'TSD-R trace missing');
fprintf('  audit ok FE=%d G1eval=%d triggers=%d triggerRate=%.4f arcEvents=%d arcCovered=%.4f recCovered=%.4f\n', ...
    ir.Evaluations,ir.TsdrG1Eval,ir.TsdrTriggers,ir.TsdrTriggerRate, ...
    ir.TsdrArcEvents,ir.TsdrArcCoveredRate,ir.TsdrRecCoveredRate);
fprintf('test_tsdr_audit_contract PASS: passive TSD-R audit bitwise identical.\n');
end
