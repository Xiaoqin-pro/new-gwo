function dbg_farE()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
rng(261013000+19*10000+3001,'twister'); pool=-100+200*rand(50,50);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,50),'upperBound',100*ones(1,50),'maxEvaluations',5000);
fc=@(x)CEC2017Function(x,19);
b2=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','farReserve',4,'farE',4);
[B2,T2,i2]=SGWO(fc,st,b2,50,3001+1000000);
fprintf('farE=%d FarN=%d FE=%d best=%.6g\n',i2.FarE,i2.FarN,i2.Evaluations,B2.Cost);
b1=b2; b1.farReserve=0; b1.farE=0;
[B1,T1,i1]=SGWO(fc,st,b1,50,3001+1000000);
fprintf('base: FarN=%d FE=%d equal=%d\n',i1.FarN,i1.Evaluations,isequal(T1,T2));
end
