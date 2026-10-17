function test_baseline_repro_smoke()
%TEST_BASELINE_REPRO_SMOKE  基线复现烟测：FE 计费 / 轨迹 / 确定性 / 模式差异。
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_baseline_repro_smoke ==\n');
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+1*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,1);
sa=st; sa.rlMode='author';
sp=st; sp.rlMode='paper';
[Ba,Ta,ia]=RLGWO_CEC(fc,sa,[],N,3001+1000000);
[Bp,Tp,ip]=RLGWO_CEC(fc,sp,[],N,3001+1000000);
[Bd,Td,id]=DMSGWO_CEC(fc,st,[],N,3001+1000000);
for c={{'RLGWO-author',Ba,Ta,ia},{'RLGWO-paper',Bp,Tp,ip},{'DMSGWO-recon',Bd,Td,id}}
    nm=c{1}{1}; B=c{1}{2}; T=c{1}{3}; inf=c{1}{4};
    assert(inf.Evaluations==budget,sprintf('%s FE mismatch: %d',nm,inf.Evaluations));
    assert(all(diff(T)<=0),sprintf('%s trace not monotone',nm));
    assert(abs(T(end)-B.Cost)<=1e-9*max(1,abs(B.Cost)),sprintf('%s T(end)~=Best',nm));
    fprintf('  %-14s ok  FE=%d  best=%.6g  rounds=%d\n',nm,inf.Evaluations,B.Cost,inf.Rounds);
end
[Ba2,Ta2]=RLGWO_CEC(fc,sa,[],N,3001+1000000);
assert(isequal(Ta,Ta2)&&Ba2.Cost==Ba.Cost,'RLGWO author not deterministic');
[Bp2,Tp2]=RLGWO_CEC(fc,sp,[],N,3001+1000000);
assert(isequal(Tp,Tp2),'RLGWO paper not deterministic');
[Bd2,Td2]=DMSGWO_CEC(fc,st,[],N,3001+1000000);
assert(isequal(Td,Td2),'DMSGWO not deterministic');
fprintf('  determinism ok (all 3)\n');
fprintf('  author vs paper identical trace? %d (should be 0)\n',isequal(Ta,Tp));
fprintf('== test_baseline_repro_smoke PASS ==\n');
end
