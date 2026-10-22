function test_rgi_audit_contract()
%TEST_RGI_AUDIT_CONTRACT  RGI passive audit must be bitwise identical.
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
sA=base; sA.rgiMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BR,TR,ir]=SGWO_RGI(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TR),'RGI audit trace differs from frozen scaffold');
assert(BA.Cost==BR.Cost && isequal(BA.Vector,BR.Vector),'RGI audit Best differs');
assert(ir.Evaluations==budget,'RGI audit FE mismatch');
assert(ir.RgiOn==1 && size(ir.RgiTrace,2)==5,'RGI trace/fields missing');
fprintf('  audit ok FE=%d triggers=%d evaluated=%d evalRate=%.4f\n', ...
    ir.Evaluations,ir.RgiTriggers,ir.RgiEvaluated,ir.RgiEvaluatedRate);
fprintf('test_rgi_audit_contract PASS: passive RGI audit bitwise identical.\n');
end
