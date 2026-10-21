function test_tsd_contract()
%TEST_TSD_CONTRACT  Shadow audit must be bitwise identical; audit counters must fire.
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
s0=base; s0.tsdMode='none';
sA=base; sA.tsdMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BN,TN]=SGWO_TSD(fc,s0,[],N,seed+1000000);
[BD,TD,ia]=SGWO_TSD(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TN) && isequal(TN,TD),'none/audit traces differ from scaffold');
assert(BA.Cost==BN.Cost && BN.Cost==BD.Cost,'none/audit Best differs');
assert(isequal(BA.Vector,BN.Vector) && isequal(BN.Vector,BD.Vector),'none/audit Vector differs');
assert(TD(end)==BD.Cost && ia.Evaluations==budget,'audit FE/Best contract failed');
assert(ia.TsdG1Eval>0 && ia.TsdEEval>0,'audit counters did not fire');
assert(ia.TsdStateSplitRate>=0 && ia.TsdStateSplitRate<=1,'invalid state-split rate');
assert(ia.TsdCursorOnlyRate>=0 && ia.TsdCursorOnlyRate<=1,'invalid cursor-only rate');
fprintf('  audit ok FE=%d G1eval=%d split=%d splitRate=%.4f Eeval=%d cursorOnly=%d cursorRate=%.4f gapDist=%.4g gapFit=%.4g\n', ...
    ia.Evaluations,ia.TsdG1Eval,ia.TsdG1Split,ia.TsdStateSplitRate, ...
    ia.TsdEEval,ia.TsdECursorOnly,ia.TsdCursorOnlyRate,ia.TsdMeanGapDist,ia.TsdMeanGapFit);
for mode={'base','full'}
    s=base; s.tsdMode=mode{1};
    [Bc,Tc,ic]=SGWO_TSD(fc,s,[],N,seed+1000000);
    assert(ic.Evaluations==budget && all(diff(Tc)<=0),sprintf('%s run broken',mode{1}));
    assert(isfield(ic,'TsdActive') && ic.TsdActive==1,sprintf('%s did not activate TSD',mode{1}));
    fprintf('  %-5s ok FE=%d cost=%.6g differsFromBaseline=%d\n',mode{1},ic.Evaluations,Bc.Cost,~isequal(Tc,TA));
end
fprintf('test_tsd_contract PASS: shadow audit bitwise; P/Z opportunities logged; base/full exact FE.\n');
end
