function test_dmsgwo_smoke()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
rng(261013000+6*10000+3001,'twister'); pool=-100+200*rand(50,30);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,30),'upperBound',100*ones(1,30),'maxEvaluations',3000);
fc=@(x)CEC2017Function(x,6);
[B,T,i]=DMSGWO_CEC(fc,st,[],50,3001+1000000);
fprintf('DMSGWO CEC F6 3k: FE=%d best=%.6g rounds=%d monotone=%d\n',i.Evaluations,B.Cost,i.Rounds,all(diff(T)<=0));
assert(i.Evaluations<=3000 && i.Evaluations>=2500 && all(diff(T)<=0));
end
