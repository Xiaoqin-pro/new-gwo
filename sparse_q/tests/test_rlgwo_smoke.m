function test_rlgwo_smoke()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
D=5; N=10; budget=4000;
rng(3,'twister'); X0=-10+20*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-10*ones(1,D),'upperBound',10*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2);
[B,T,i]=RLGWO_CEC(f,st,[],N,7);
fprintf('RLGWO smoke: FE=%d best=%.6g rounds=%d monotone=%d\n',i.Evaluations,B.Cost,i.Rounds,all(diff(T)<=0));
assert(i.Evaluations<=budget && i.Evaluations>=budget-N);
assert(all(diff(T)<=0) && T(i.Evaluations)==B.Cost);
cd(fullfile(root,'data','cec2017'));
fc=@(x)CEC2017Function(x,6);
rng(261013000+6*10000+3001,'twister'); pool=-100+200*rand(50,30);
st2=struct('initialPopulation',pool,'lowerBound',-100*ones(1,30),'upperBound',100*ones(1,30),'maxEvaluations',3000);
[B2,~,i2]=RLGWO_CEC(fc,st2,[],50,3001+1000000);
fprintf('RLGWO CEC F6 3k: FE=%d best=%.6g\n',i2.Evaluations,B2.Cost);
end
