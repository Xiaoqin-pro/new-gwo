function test_vitf_audit_contract()
%TEST_VITF_AUDIT_CONTRACT  VITF passive audit must be bitwise identical.
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
sA=base; sA.tsdMode='audit'; sA.vitfMode='audit'; sA.vitfLambda=0.5;
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BV,TV,iv]=SGWO_TSD(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TV),'VITF audit trace differs from frozen scaffold');
assert(BA.Cost==BV.Cost && isequal(BA.Vector,BV.Vector),'VITF audit Best differs');
assert(iv.Evaluations==budget,'VITF audit FE mismatch');
assert(iv.VitfG1Opp>0 && iv.VitfEvents>0,'VITF audit did not record opportunities');
assert(iv.VitfArcEvents>0 && iv.VitfAngleCount>0,'VITF archive/angle events missing');
assert(iv.VitfActiveRate>=0 && iv.VitfActiveRate<=1,'invalid VITF activation rate');
fprintf('  audit ok FE=%d opp=%d active=%d activeRate=%.4f angleCount=%d meanAngle=%.3f angle10Rate=%.4f arcEvents=%d arcDist=%.4g usefulIndepRate=%.4f\n', ...
    iv.Evaluations,iv.VitfG1Opp,iv.VitfEvents,iv.VitfActiveRate,iv.VitfAngleCount, ...
    iv.VitfMeanAngle,iv.VitfAngle10Rate,iv.VitfArcEvents,iv.VitfMeanArcDist,iv.VitfUsefulIndependentRate);
fprintf('test_vitf_audit_contract PASS: passive VITF audit bitwise identical.\n');
end
