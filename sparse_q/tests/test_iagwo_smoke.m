function test_iagwo_smoke()
%TEST_IAGWO_SMOKE  IAGWO 契约与计费烟测（同 test_baseline3_smoke 口径）。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
D=5; N=10; budget=4000;
rng(3,'twister'); X0=-10+20*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-10*ones(1,D),'upperBound',10*ones(1,D), ...
    'maxEvaluations',budget);
f=@(x)sum(x.^2);
[B,T,i]=IAGWO_CEC(f,st,[],N,7);
assert(i.Evaluations==budget);
assert(all(diff(T)<=0));
assert(abs(T(budget)-B.Cost)<=1e-12*max(1,abs(B.Cost)));
assert(abs(f(B.Vector)-B.Cost)<=1e-12*max(1,abs(B.Cost)));
[B2,~,~]=IAGWO_CEC(f,st,[],N,7);
assert(abs(B2.Cost-B.Cost)<=1e-12*max(1,abs(B.Cost)));
fprintf('IAGWO smoke: FE=%d best=%.6g rounds=%d phi mean=%.3f std=%.3f\n', ...
    i.Evaluations,B.Cost,i.Rounds,i.PhiMean,i.PhiStd);
cd(fullfile(root,'data','cec2017'));
fc=@(x)CEC2017Function(x,6);
rng(261013000+6*10000+3001,'twister'); pool=-100+200*rand(50,30);
st2=struct('initialPopulation',pool,'lowerBound',-100*ones(1,30), ...
    'upperBound',100*ones(1,30),'maxEvaluations',3000);
[B3,~,i3]=IAGWO_CEC(fc,st2,[],50,3001+1000000);
fprintf('IAGWO CEC F6 3k: FE=%d best=%.6g phi mean=%.3f std=%.3f\n', ...
    i3.Evaluations,B3.Cost,i3.PhiMean,i3.PhiStd);
st3=st2; st3.iagwoPhiMode='raw';
[B4,~,i4]=IAGWO_CEC(fc,st3,[],50,3001+1000000);
fprintf('IAGWO CEC F6 3k (raw phi): FE=%d best=%.6g phi mean=%.3f std=%.3f\n', ...
    i4.Evaluations,B4.Cost,i4.PhiMean,i4.PhiStd);
fprintf('test_iagwo_smoke PASS\n');
end
