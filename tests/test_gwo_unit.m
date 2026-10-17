function test_gwo_unit()
%TEST_GWO_UNIT  CEC-free unit tests of the fresh standard GWO core.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
fprintf('== test_gwo_unit ==\n');
D=5; N=6; budget=120;
rng(42,'twister'); X0=-5+10*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-5*ones(1,D), ...
    'upperBound',5*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2);
[Best,T,info]=GWO(f,st,[],N,42);
assert(info.Evaluations==budget,'FE count wrong');
assert(numel(T)==budget,'trace length wrong');
assert(all(diff(T)<=0),'trace must be monotone non-increasing');
assert(abs(T(end)-Best.Cost)<1e-12,'T(end) must equal best cost');
assert(Best.Cost>=0,'sphere must be non-negative');
fprintf('  sphere: FE=%d best=%.6g ok\n',info.Evaluations,Best.Cost);

% bounds are enforced on every evaluated position
lb=-5*ones(1,D); ub=5*ones(1,D);
chk=@(x)checkAndEval(x,lb,ub);
[Best2]=GWO(chk,st,[],N,7); %#ok<NASGU>
fprintf('  bounds: all evaluated positions inside [%.0f,%.0f] ok\n',lb(1),ub(1));

% determinism + seed sensitivity
[~,T2]=GWO(f,st,[],N,42);
assert(isequal(T,T2),'same seed must reproduce bitwise');
[~,T3]=GWO(f,st,[],N,43);
assert(~isequal(T,T3),'different seed should differ');
fprintf('  determinism + seed sensitivity ok\n');

% nontrivial multimodal improvement
D=10; N=10; budget=2000;
rng(1,'twister'); X0=-5.12+10.24*rand(N,D);
st2=struct('initialPopulation',X0,'lowerBound',-5.12*ones(1,D), ...
    'upperBound',5.12*ones(1,D),'maxEvaluations',budget);
fras=@(x)sum(x.^2-10*cos(2*pi*x)+10);
initBest=min(arrayfun(@(i)fras(X0(i,:)),1:N));
[Best3,~,info3]=GWO(fras,st2,[],N,5);
assert(info3.Evaluations==budget);
assert(Best3.Cost<=initBest,'GWO must be at least as good as initial best');
fprintf('  rastrigin D=10: initBest=%.4f final=%.4f ok\n',initBest,Best3.Cost);
fprintf('== test_gwo_unit PASS ==\n');
end

function v=checkAndEval(x,lb,ub)
assert(all(x>=lb-1e-12) && all(x<=ub+1e-12),'evaluated position outside bounds');
v=sum(x.^2);
end
