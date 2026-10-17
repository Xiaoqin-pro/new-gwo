function time_s1_d50()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cd(fullfile(root,'data','cec2017'));
fid=13; D=50; budget=100000;
rng(261013000+fid*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget);
f=@(x)CEC2017Function(x,fid);
s=st; s.mode='sparse'; s.K=50; s.nG2=12; s.nE=38; s.screenPolicy='random';
t0=tic; [B,T,i]=SGWO(f,s,[],50,3001+1000000); el=toc(t0);
fprintf('S1 D50/100k F13: %.2fs best=%.6g FE=%d rounds=%d\n',el,B.Cost,i.Evaluations,i.Rounds);
s2=st; s2.mode='sparse'; s2.K=10; s2.nG2=12; s2.nE=38; s2.screenPolicy='random';
t0=tic; [B2,~,i2]=SGWO(f,s2,[],50,3001+1000000); el2=toc(t0);
fprintf('S1-K10 D50/100k F13: %.2fs best=%.6g rounds=%d\n',el2,B2.Cost,i2.Rounds);
end
