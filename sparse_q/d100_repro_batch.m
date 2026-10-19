function out=d100_repro_batch()
%D100_REPRO_BATCH  Re-run all 290 archived D=100 VAST-GWO jobs (29 fn x 10 seeds)
%   with the CURRENT frozen implementation, into a NEW directory (no overwrite).
%   Used only to prove implementation/protocol compatibility before reuse.
sq=fileparts(mfilename('fullpath')); root=fileparts(sq);
addpath(fullfile(root,'src'),fullfile(root,'data','cec2017'),fullfile(sq,'src'),fullfile(sq,'experiments'),fullfile(root));
D=100; funcs=[1 3:30]; seeds=3001:3010; maxFE=100000;
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
opt=struct(); opt.states={sStar}; opt.labels={'S-star'};
tag='d100repro';
out=run_batch_sq(tag,{'SGWO'},funcs,seeds,D,maxFE,opt);
disp(out.summary);
end
