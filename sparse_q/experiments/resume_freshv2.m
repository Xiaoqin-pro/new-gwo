function out=resume_freshv2()
%RESUME_FRESHV2  断点续跑：只补 IGWO 臂的 870 次失败运行（其余 4350 已完成）。
%   注意：jobs 必须与 manifest 完全一致（同一构建函数）。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here);
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),sqRoot);
dirs=dir(fullfile(sqRoot,'results','freshv2_*'));
assert(~isempty(dirs),'no freshv2 batch');
outDir=fullfile(sqRoot,'results',dirs(end).name);
fprintf('resuming: %s\n',outDir);
funcs=[1 3:30]; seeds=3031:3060; D=50; maxFE=100000;
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
s25=base; s25.succSteer=0.25;
s50=base; s50.succSteer=0.5;
g20=base; g20.g2Subset=0.2;
k5=base; k5.K=5;
algs={'SGWO','SGWO','SGWO','SGWO','SGWO','IGWO'};
labels={'V1-frozen','V2-steer25','V2-steer50','V2-subset20','V2-K5','IGWO-fresh'};
states=cell(1,6); states{1}=base; states{2}=s25; states{3}=s50; states{4}=g20; states{5}=k5; states{6}=struct();
opt=struct(); opt.states=states; opt.labels=labels; opt.resume=outDir;
out=run_batch_sq('freshv2',algs,funcs,seeds,D,maxFE,opt);
end
