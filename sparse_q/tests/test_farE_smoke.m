function test_farE_smoke()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
rng(261013000+19*10000+3001,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',30000);
fc=@(x)CEC2017Function(x,19);
b1=st; b1.mode='sparse'; b1.K=10; b1.nG2=12; b1.nE=38; b1.screenPolicy='random';
b2=b1; b2.farReserve=4; b2.farE=4;
[B1,T1,i1]=SGWO(fc,b1,[],50,3001+1000000);
[B2,T2,i2]=SGWO(fc,b2,[],50,3001+1000000);
fprintf('base: FE=%d best=%.6g | farE4: FE=%d best=%.6g FarN=%d equal=%d\n', ...
    i1.Evaluations,B1.Cost,i2.Evaluations,B2.Cost,i2.FarN,isequal(T1,T2));
assert(i1.Evaluations==30000 && i2.Evaluations==30000 && ~isequal(T1,T2));
end
