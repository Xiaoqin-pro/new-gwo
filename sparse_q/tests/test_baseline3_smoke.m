function test_baseline3_smoke()
%TEST_BASELINE3_SMOKE  新增外部基线（MENGWO 2025 / IAGWO 2024）契约与计费烟测：
%   FE 精确、轨迹单调、T(end)==Best、确定性、CEC2017 可跑。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
D=5; N=10; budget=4000;
rng(3,'twister'); X0=-10+20*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-10*ones(1,D),'upperBound',10*ones(1,D), ...
    'maxEvaluations',budget);
f=@(x)sum(x.^2);
algs={'MENGWO_CEC','IAGWO_CEC'};
for a=1:numel(algs)
    fn=str2func(algs{a});
    [B,T,i]=fn(f,st,[],N,7);
    assert(i.Evaluations==budget,sprintf('%s: FE=%d != budget',algs{a},i.Evaluations));
    assert(all(diff(T)<=0),sprintf('%s: trace not monotone',algs{a}));
    assert(abs(T(budget)-B.Cost)<=1e-12*max(1,abs(B.Cost)),sprintf('%s: T(end)~=Best',algs{a}));
    assert(f(B.Vector)<=B.Cost+1e-12,sprintf('%s: Best.Vector inconsistent',algs{a}));
    [B2,~,~]=fn(f,st,[],N,7);
    assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)),sprintf('%s: not deterministic',algs{a}));
    fprintf('%-20s smoke: FE=%d best=%.6g rounds=%d ok\n',algs{a},i.Evaluations,B.Cost,i.Rounds);
end
% CEC2017 30D 小预算
cd(fullfile(root,'data','cec2017'));
fc=@(x)CEC2017Function(x,6);
rng(261013000+6*10000+3001,'twister'); pool=-100+200*rand(50,30);
st2=struct('initialPopulation',pool,'lowerBound',-100*ones(1,30), ...
    'upperBound',100*ones(1,30),'maxEvaluations',3000);
for a=1:numel(algs)
    fn=str2func(algs{a});
    [B,~,i]=fn(fc,st2,[],50,3001+1000000);
    assert(i.Evaluations==3000);
    fprintf('%-20s CEC F6 3k: FE=%d best=%.6g\n',algs{a},i.Evaluations,B.Cost);
end
fprintf('test_baseline3_smoke PASS\n');
end
