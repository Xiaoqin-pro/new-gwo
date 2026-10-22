function test_reuse_tsdbase()
%TEST_REUSE_TSDBASE  Reproduce an old C-TSDbase run before reusing 870 runs.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'),fullfile(root,'experiments'));
oldFile=fullfile(cfg.root,'sparse_q','results','tsd_confirm_bc_20261021_101017','runs','run_00002.mat');
assert(exist(oldFile,'file')==2,'missing old TSD-base run file');
a=load(oldFile,'record'); old=a.record.result;
job=struct('algorithm','SGWO_TSD','label','C-TSDbase','fid',1,'D',50,'seed',3071, ...
    'maxFE',100000,'N',50,'useProbe',true, ...
    'state',struct('mode','sparse','K',10,'nG2',12,'nE',38, ...
                   'screenPolicy','random','ablateG2',1,'ablateE',0, ...
                   'tsdMode','base','tsdrMode','none'));
new=runner_sgwo(job);
dc=abs(new.BestCost-old.BestCost);
dv=max(abs(new.BestVector-old.BestVector));
fprintf('TSD-base reuse audit: oldCost=%.12g newCost=%.12g dCost=%.3g dVec=%.3g\n', ...
    old.BestCost,new.BestCost,dc,dv);
assert(dc<=1e-9*max(1,abs(old.BestCost)),'TSD-base BestCost not reproduced');
assert(dv<=1e-12,'TSD-base BestVector not reproduced');
assert(new.Evaluations==old.Evaluations && new.Evaluations==100000,'TSD-base FE mismatch');
fprintf('test_reuse_tsdbase PASS: old C-TSDbase is bitwise reproducible.\n');
end
