function diag_weighted_share()
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'));
cecDir=fullfile(root,'data','cec2017'); cd(cecDir);
D=30; rng(1,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',500);
f=@(x)CEC2017Function(x,1);
for q=[0.25 0.5 0.75]
    s=st; s.mode='sparse'; s.K=50; s.nG2=12; s.nE=38; s.screenPolicy='weighted'; s.quotaPolicy='fixed'; s.quotaFixed=q;
    [~,~,info]=SGWO(f,s,[],50,7);
    fprintf('qE=%.2f -> gen1 [G1 G2 E]=[%d %d %d]\n',q,info.Gen1SrcCounts);
end
end
