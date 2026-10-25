function quick_cma_phase_diag()
root=fileparts(fileparts(mfilename('fullpath'))); cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=50; N=50; budget=100000; seed=4191; fids=[1 7 10 20];
for fid=fids
    rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
    s=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D),'maxEvaluations',budget,'cmaMixMode','always','cmaMixFraction',0);
    [B,T,i]=CMA_DE_CEC(@(x)CEC2017Function(x,fid),s,[],N,seed+1000000);
    tr=i.CmaMixTrace; checks=[10000 20000 30000 50000 70000 90000 100000];
    fprintf('\nF%d best=%.6g rounds=%d\n',fid,B.Cost,i.Rounds);
    fprintf('FE sigma cond stag selMedian best useMix\n');
    for q=checks
        [~,r]=min(abs(tr(:,2)-q)); fprintf('%6d %.4g %.4g %d %.6g %.6g %d\n',tr(r,2),tr(r,5),tr(r,9),tr(r,3),tr(r,7),tr(r,6),tr(r,8));
    end
end
end

