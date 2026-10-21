function test_g2tr_contract()
%TEST_G2TR_CONTRACT  Unit contract for the G2 trust-region implementation.
%  Checks true-FE accounting, per-source evaluation counts, radius bounds,
%  trace length, and the no-instrumentation-equivalence requirement.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+1*10000+3997,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
tr=base; tr.g2RadiusMode='trust'; tr.g2R0=0.01; tr.g2RMin=0.001; tr.g2RMax=0.05;
tr.g2Expand=1.25; tr.g2Shrink=0.8;
s=st; fn=fieldnames(tr); for k=1:numel(fn), s.(fn{k})=tr.(fn{k}); end
fc=@(x)CEC2017Function(x,1);
[B,T,info]=SGWO_TR(fc,s,[],N,3997+1000000);
assert(info.Evaluations==budget,'FE mismatch');
assert(all(diff(T)<=0) && abs(T(end)-B.Cost)<=1e-9*max(1,abs(B.Cost)),'trace broken');
assert(all(info.EvalCnt>=0),'negative source count');
assert(info.G2EvalCount==info.EvalCnt(2),'G2 evaluation counter mismatch');
assert(size(info.G2RadiusTrace,1)==info.G2EvalCount,'radius trace length mismatch');
assert(all(info.G2RadiusTrace(:,2)>=tr.g2RMin-1e-15 & info.G2RadiusTrace(:,2)<=tr.g2RMax+1e-15),'radius bound violated');
assert(all(diff(info.G2RadiusTrace(:,1))>0),'radius trace FE not strictly increasing');
% Base SGWO_ABLATION must remain bitwise equal to frozen SGWO after the
% measurement-only instrumentation patch.
[BA,TA]=SGWO(fc,st,[],N,3997+1000000);
[BB,TB,ib]=SGWO_ABLATION(fc,st,[],N,3997+1000000);
assert(isequal(TA,TB) && BA.Cost==BB.Cost,'instrumentation changed base trace');
assert(ib.Evaluations==budget && sum(ib.EvalCnt)>0,'base instrumentation broken');
fprintf('test_g2tr_contract PASS: G2Eval=%d, radiusEnd=%.5g, base FE=%d\n', ...
    info.G2EvalCount,info.G2RadiusEnd,ib.Evaluations);
end
