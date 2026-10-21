function test_reuse_a2()
%TEST_REUSE_A2  Reproduce one ablcore A2-G1E scalar result before reusing the 870-run arm.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'),fullfile(root,'experiments'));
oldCsv=fullfile(cfg.root,'sparse_q','results','ablcore_20261017_062209','runs.csv');
assert(exist(oldCsv,'file')==2,'missing old A2 runs.csv');
T=readtable(oldCsv);
mask=T.Algorithm=="A2-G1E" & T.FunctionID==1 & T.Seed==3071;
assert(nnz(mask)==1,'unexpected old A2 row count');
oldCost=T.BestCost(mask); oldFE=T.Evaluations(mask);
job=struct('algorithm','SGWOAB','label','A2-G1E','fid',1,'D',50,'seed',3071, ...
    'maxFE',100000,'N',50,'useProbe',true, ...
    'state',struct('mode','sparse','K',10,'nG2',12,'nE',38, ...
                   'screenPolicy','random','ablateG2',1));
new=runner_sgwo(job);
dc=abs(new.BestCost-oldCost);
fprintf('A2 reuse audit: oldCost=%.12g newCost=%.12g dCost=%.3g oldFE=%d newFE=%d\n', ...
    oldCost,new.BestCost,dc,oldFE,new.Evaluations);
assert(dc<=1e-9*max(1,abs(oldCost)),'A2 BestCost not reproduced');
assert(new.Evaluations==oldFE && new.Evaluations==100000,'A2 FE mismatch');
fprintf('test_reuse_a2 PASS: ablcore A2-G1E scalar result reproduced.\n');
end
