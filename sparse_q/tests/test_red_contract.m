function test_red_contract()
%TEST_RED_CONTRACT  none/audit must stay bitwise identical; drop must keep FE exact.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
sN=base; sN.redMode='none';
[BN,TN]=SGWO_RED(fc,sN,[],N,seed+1000000);
assert(isequal(TA,TN) && BA.Cost==BN.Cost,'RED none differs from frozen scaffold');
sA=base; sA.redMode='audit'; sA.redEps=0.02;
[BAu,TAu,iA]=SGWO_RED(fc,sA,[],N,seed+1000000);
assert(isequal(TA,TAu) && BA.Cost==BAu.Cost,'RED audit differs from frozen scaffold');
fprintf('  audit ok FE=%d dupRate=%.3f dupImp=%.3f distImp=%.3f dupArc=%.3f distArc=%.3f\n', ...
    iA.Evaluations,iA.RedSelDupRate,iA.RedDupImpRate,iA.RedDistImpRate,iA.RedDupArcRate,iA.RedDistArcRate);
sD=base; sD.redMode='drop'; sD.redEps=0.02; sD.redMaxDraw=5;
[BD,TD,iD]=SGWO_RED(fc,sD,[],N,seed+1000000);
assert(iD.Evaluations==budget && all(diff(TD)<=0),'drop run broken');
assert(iD.RedRejects>0,'drop never rejected a redundant candidate');
assert(iD.RedSelDupRate<0.35,sprintf('drop duplicate rate too high: %.3f',iD.RedSelDupRate));
fprintf('  drop  ok FE=%d rejects=%d draws=%d dupRate=%.3f (audit %.3f) dupImp=%.3f distImp=%.3f\n', ...
    iD.Evaluations,iD.RedRejects,iD.RedDraws,iD.RedSelDupRate,iA.RedSelDupRate,iD.RedDupImpRate,iD.RedDistImpRate);
sM=base; sM.redMode='drop'; sM.redEps=0.005; sM.redMaxDraw=5;
[~,~,iM]=SGWO_RED(fc,sM,[],N,seed+1000000);
assert(iM.Evaluations==budget,'mild drop FE mismatch');
fprintf('  mild  ok FE=%d rejects=%d dupRate=%.3f\n',iM.Evaluations,iM.RedRejects,iM.RedSelDupRate);
fprintf('test_red_contract PASS.\n');
end
