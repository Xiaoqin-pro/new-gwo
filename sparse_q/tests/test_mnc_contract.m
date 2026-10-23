function test_mnc_contract()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=12000; seed=4027; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'mncMode','fixed','mncK',3);
fc=@(x)CEC2017Function(x,fid);
[B,T,i]=MNC_CMA_CEC(fc,base,[],N,seed+1000000);
assert(i.Evaluations==budget && numel(T)==budget && abs(T(end)-B.Cost)<1e-12);
assert(i.NicheK==3 && all(i.NicheEval>0));
fprintf('mnc ok FE=%d rounds=%d niches=%s best=%.6g\n',i.Evaluations,i.Rounds,mat2str(i.NicheEval),B.Cost);
s=base; s.mncMode='adaptive'; [B2,T2,i2]=MNC_CMA_CEC(fc,s,[],N,seed+1000000); assert(i2.Evaluations==budget && numel(T2)==budget); fprintf('mnc adaptive ok best=%.6g shares=%s\n',B2.Cost,mat2str(i2.NicheShares,3));
end
