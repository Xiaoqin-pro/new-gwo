function test_pso_smoke()
%TEST_PSO_SMOKE  经典 PSO 烟测：FE 精确 / 轨迹单调 / 确定性。
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_pso_smoke ==\n');
cd(cfg.cecDir);
D=30; N=50; budget=3000;
rng(261013000+1*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,1);
[B,T,inf]=PSO_CEC(fc,st,[],N,3001+1000000);
assert(inf.Evaluations==budget,sprintf('FE=%d',inf.Evaluations));
assert(all(diff(T)<=0),'trace not monotone');
assert(abs(T(end)-B.Cost)<=1e-9*max(1,abs(B.Cost)),'T(end)~=Best');
[B2,T2]=PSO_CEC(fc,st,[],N,3001+1000000);
assert(isequal(T,T2)&&B2.Cost==B.Cost,'not deterministic');
fprintf('  PSO ok  FE=%d  best=%.6g  rounds=%d\n',inf.Evaluations,B.Cost,inf.Rounds);
fprintf('== test_pso_smoke PASS ==\n');
end
