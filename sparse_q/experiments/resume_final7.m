function out=resume_final7()
%RESUME_FINAL7  断点续跑：定位最新 final7_* 目录并按同一 manifest 续跑（可多次中断/恢复）。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here);
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),sqRoot);
dirs=dir(fullfile(sqRoot,'results','final7_*'));
assert(~isempty(dirs),'no final7 batch');
outDir=fullfile(sqRoot,'results',dirs(end).name);
fprintf('resuming: %s\n',outDir);
funcs=[1 3:30]; seeds=3001:3030; D=50; maxFE=100000;
sa=struct('rlMode','author'); sp=struct('rlMode','paper');
algs={'RLGWO','RLGWO','DMSGWO'};
labels={'RL-LGWO(author)','RL-LGWO(paper)','DMSGWO(recon)'};
states=cell(1,3); states{1}=sa; states{2}=sp; states{3}=struct();
opt=struct(); opt.states=states; opt.labels=labels; opt.resume=outDir;
out=run_batch_sq('final7',algs,funcs,seeds,D,maxFE,opt);
end
