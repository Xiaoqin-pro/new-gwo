function test_succsteer_smoke()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
D=30; fid=6; budget=3000;
rng(261013000+fid*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
f=@(x)CEC2017Function(x,fid);
a=st; a.mode='sparse'; a.K=10; a.nG2=12; a.nE=38; a.screenPolicy='random';
b=a; b.succSteer=0.25; b.stagnBoost=3;
[Ba,Ta,ia]=SGWO(f,a,[],50,3001+1000000);
[Bb,Tb,ib]=SGWO(f,b,[],50,3001+1000000);
fprintf('off: FE=%d best=%.6g | steer+boost: FE=%d best=%.6g equalT=%d\n',ia.Evaluations,Ba.Cost,ib.Evaluations,Bb.Cost,isequal(Ta,Tb));
assert(ia.Evaluations==budget && ib.Evaluations==budget);
end
