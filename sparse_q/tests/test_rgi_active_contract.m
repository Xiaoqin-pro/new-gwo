function test_rgi_active_contract()
%TEST_RGI_ACTIVE_CONTRACT  Audit/on/stall contract and exact FE.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=5000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
for mode={'audit','on','stall'}
    s=base; s.rgiMode=mode{1}; s.rgiConsecFail=3; s.rgiWorstFrac=0.5; s.rgiSeedOffset=444444;
    [B,T,inf1]=SGWO_RGI(fc,s,[],N,seed+1000000);
    assert(inf1.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',mode{1}));
    fprintf('  %-5s ok cost=%.6g triggers=%d restarts=%d evalRestarts=%d\n', ...
        mode{1},B.Cost,inf1.RgiTriggers,inf1.RgiRestarts,inf1.RgiEvaluatedRestarts);
end
fprintf('test_rgi_active_contract PASS: audit/on/stall exact FE.\n');
end
