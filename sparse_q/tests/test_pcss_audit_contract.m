function test_pcss_audit_contract()
%TEST_PCSS_AUDIT_CONTRACT  PCSS passive audit must be bitwise identical.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
sA=base; sA.pcssMode='audit'; sA.pcssK=5; sA.pcssCap=256;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BP,TP,ip]=SGWO_PCSS(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TP),'PCSS audit trace differs from frozen scaffold');
assert(BA.Cost==BP.Cost && isequal(BA.Vector,BP.Vector),'PCSS audit Best differs');
assert(ip.Evaluations==budget,'PCSS audit FE mismatch');
assert(ip.PcssOn==1 && ip.PcssN>0,'PCSS audit counters missing');
fprintf('  audit ok FE=%d pcssN=%d predSamples=%d\n',ip.Evaluations,ip.PcssN,numel(ip.PcssPred));
fprintf('test_pcss_audit_contract PASS: passive PCSS audit bitwise identical.\n');
end
