function test_new3_smoke()
%TEST_NEW3_SMOKE  三个新基线（HAGWO/AOGWO/EDGWO）烟测：FE 精确 / 轨迹单调 / 确定性。
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_new3_smoke ==\n');
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+1*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,1);
fns={'HAGWO_CEC','AOGWO_CEC','EDGWO_CEC'};
for k=1:3
    g=str2func(fns{k});
    [B,T,inf]=g(fc,st,[],N,3001+1000000);
    assert(inf.Evaluations==budget,sprintf('%s FE=%d',fns{k},inf.Evaluations));
    assert(all(diff(T)<=0),sprintf('%s trace not monotone',fns{k}));
    assert(abs(T(end)-B.Cost)<=1e-9*max(1,abs(B.Cost)),sprintf('%s T(end)~=Best',fns{k}));
    [B2,T2]=g(fc,st,[],N,3001+1000000);
    assert(isequal(T,T2)&&B2.Cost==B.Cost,sprintf('%s not deterministic',fns{k}));
    fprintf('  %-11s ok  FE=%d  best=%.6g  rounds=%d\n',fns{k},inf.Evaluations,B.Cost,inf.Rounds);
end
fprintf('== test_new3_smoke PASS ==\n');
end
