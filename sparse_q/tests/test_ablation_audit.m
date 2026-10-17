function test_ablation_audit()
%TEST_ABLATION_AUDIT  消融实现审计：
%  (1) A3（槽位全保留）与冻结 SGWO.m 同种子逐位一致（Trace 与 Best）；
%  (2) 五臂 FE 精确计费、轨迹单调、可运行；
%  (3) 来源级改善计数器自洽（非负、有改善时为正）。
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_ablation_audit ==\n');
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+1*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
fc=@(x)CEC2017Function(x,1);
[BA,TA]=SGWO(fc,st,[],N,3001+1000000);
[A3B,A3T]=SGWO_ABLATION(fc,st,[],N,3001+1000000);
assert(isequal(TA,A3T),'A3 trace must be bitwise equal to frozen SGWO');
assert(A3B.Cost==BA.Cost && isequal(A3B.Vector,BA.Vector),'A3 best must match frozen SGWO');
fprintf('  (1) bitwise A3 == SGWO ok (F1 best=%.10g)\n',A3B.Cost);
fc6=@(x)CEC2017Function(x,6);
[~,T6]=SGWO(fc6,st,[],N,3002+1000000);
[~,T6a]=SGWO_ABLATION(fc6,st,[],N,3002+1000000);
assert(isequal(T6,T6a),'A3 trace must be bitwise equal (F6)');
fprintf('  (1) bitwise A3 == SGWO ok (F6)\n');
arms={struct('ablateG2',1,'ablateE',1), base, struct('ablateG2',1), struct('ablateE',1), struct('alphaSingleE',1)};
names={'A0-GWOonly','A3-V1full','A2-G1E','A1-G1G2','A5-NoArchive'};
for k=1:numel(arms)
    s=st; fn=fieldnames(arms{k});
    for q=1:numel(fn), s.(fn{q})=arms{k}.(fn{q}); end
    [B,T,inf]=SGWO_ABLATION(fc,s,[],N,3100+k);
    assert(inf.Evaluations==budget,sprintf('%s FE mismatch',names{k}));
    assert(all(diff(T)<=0) && abs(T(end)-B.Cost)<=1e-9*max(1,abs(B.Cost)),sprintf('%s trace broken',names{k}));
    assert(all(inf.ImpCnt>=0) && all(inf.ImpMag>=0),sprintf('%s counters negative',names{k}));
    assert(sum(inf.ImpCnt)>0,sprintf('%s no improvements recorded',names{k}));
    fprintf('  (2)(3) %-13s ok  ImpCnt=[%d %d %d %d]  ImpMag=[%.3g %.3g %.3g %.3g]\n', ...
        names{k},inf.ImpCnt,inf.ImpMag);
end
fprintf('== test_ablation_audit PASS ==\n');
end
