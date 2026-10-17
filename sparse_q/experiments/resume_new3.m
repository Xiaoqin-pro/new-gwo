function out=resume_new3()
%RESUME_NEW3  断点续跑：定位最新 new3_* 目录并按同一 manifest 续跑。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here);
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),sqRoot);
dirs=dir(fullfile(sqRoot,'results','new3_*'));
assert(~isempty(dirs),'no new3 batch');
outDir=fullfile(sqRoot,'results',dirs(end).name);
fprintf('resuming: %s\n',outDir);
funcs=[1 3:30]; seeds=3001:3030; D=50; maxFE=100000;
algs={'HAGWO','AOGWO','EDGWO'};
labels={'HAGWO','AOGWO','EDGWO'};
states=cell(1,3);
opt=struct(); opt.states=states; opt.labels=labels; opt.resume=outDir;
out=run_batch_sq('new3',algs,funcs,seeds,D,maxFE,opt);
end
