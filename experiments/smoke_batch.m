function smoke_batch()
%SMOKE_BATCH  Minimal 4-worker wiring test (2 algorithms x 2 functions x 1 seed).
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(cfg.root,'experiments'),cfg.root);
algs={'GWO','ANGWO'};
labels={'GWO','ANGWO-smoke'};
states=cell(1,2);
states{2}=struct('exploreMode','adaptive','recoveryMode','stagnation');
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('smoke',algs,[1 6],3001,30,3000,opt);
disp(out.summary);
end

