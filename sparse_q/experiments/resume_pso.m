function out=resume_pso()
%RESUME_PSO  断点续跑：定位最新 pso_* 目录并按同一 manifest 续跑。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here);
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),sqRoot);
dirs=dir(fullfile(sqRoot,'results','pso_*'));
assert(~isempty(dirs),'no pso batch');
outDir=fullfile(sqRoot,'results',dirs(end).name);
fprintf('resuming: %s\n',outDir);
funcs=[1 3:30]; seeds=3001:3030; D=50; maxFE=100000;
algs={'PSO'}; labels={'PSO(classic)'}; states=cell(1,1);
opt=struct(); opt.states=states; opt.labels=labels; opt.resume=outDir;
out=run_batch_sq('pso',algs,funcs,seeds,D,maxFE,opt);
end
