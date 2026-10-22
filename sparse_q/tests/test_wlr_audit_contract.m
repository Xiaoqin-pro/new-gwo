function test_wlr_audit_contract()
%TEST_WLR_AUDIT_CONTRACT  WLR audit must be bitwise identical to frozen G1+E.
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
sA=base; sA.wlrMode='audit';
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
[BW,TW,iw]=SGWO_WLR(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TW),'WLR audit trace differs from frozen scaffold');
assert(BA.Cost==BW.Cost && isequal(BA.Vector,BW.Vector),'WLR audit Best differs');
assert(iw.Evaluations==budget,'WLR audit FE mismatch');
assert(iw.WlrMacroGens>0 && iw.WlrEvaluatedG1>0,'WLR audit counters missing');
assert(iw.WlrLeaderChanges>0 && iw.WlrStaleCount>0,'WLR never saw leader change/stale candidates');
fprintf('  audit ok FE=%d macroGens=%d leaderChanges=%d stale=%d staleRate=%.4f medianDist=%.4g p90Dist=%.4g\n', ...
    iw.Evaluations,iw.WlrMacroGens,iw.WlrLeaderChanges,iw.WlrStaleCount,iw.WlrStaleRate, ...
    iw.WlrMedianStaleDist,iw.WlrP90StaleDist);
fprintf('test_wlr_audit_contract PASS: passive WLR audit bitwise identical.\n');
end
