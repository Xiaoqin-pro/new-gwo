function test_dse_contract()
%TEST_DSE_CONTRACT  none must stay bitwise identical; cauchy/gauss must run with exact FE.
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
sN=base; sN.dseMode='none';
[BN,TN,iN]=SGWO_DSE(fc,sN,[],N,seed+1000000);
assert(isequal(TA,TN) && BA.Cost==BN.Cost,'DSE none differs from frozen scaffold');
fprintf('  none ok FE=%d cost=%.6g (bitwise frozen)\n',iN.Evaluations,BN.Cost);
% longer budget so the dual gate can fire
budget2=20000; base2=base; base2.maxEvaluations=budget2;
[~,Tf]=SGWO_ABLATION(fc,base2,[],N,seed+1000000);
for spec={'cauchy','gauss'}
    s=base2; s.dseMode=spec{1};
    [B,T,i1]=SGWO_DSE(fc,s,[],N,seed+1000000);
    assert(i1.Evaluations==budget2 && all(diff(T)<=0),sprintf('%s run broken',spec{1}));
    assert(i1.DseUsed>0,sprintf('%s never escaped (gate never fired)',spec{1}));
    assert(i1.DseUsedFrac<=0.05+1e-12,'escape budget exceeded');
    fprintf('  %-6s ok FE=%d used=%d (%.4f of budget) firstFE=%d popAcc=%d arcAcc=%d\n', ...
        spec{1},i1.Evaluations,i1.DseUsed,i1.DseUsedFrac,i1.DseFirstFE,i1.DsePopAcc,i1.DseArcAcc);
end
sC=base2; sC.dseMode='cauchy';
[~,TC]=SGWO_DSE(fc,sC,[],N,seed+1000000);
assert(~isequal(TC,Tf),'DSE cauchy did not change the search');
fprintf('  cauchy differs from frozen trace at 20k\n');
fprintf('test_dse_contract PASS.\n');
end
