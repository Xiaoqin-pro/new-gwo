function test_reuse_steer_baselines()
%TEST_REUSE_STEER_BASELINES  SGWO_STEER(none) must reproduce ablcore A2-G1E and A0-GWOonly.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'),fullfile(root,'experiments'));
oldCsv=fullfile(cfg.root,'sparse_q','results','ablcore_20261017_062209','runs.csv');
assert(exist(oldCsv,'file')==2,'missing ablcore runs.csv');
T=readtable(oldCsv);
cells={ {'A2-G1E',1,3071}, {'A0-GWOonly',1,3071}, {'A2-G1E',30,3100}, {'A0-GWOonly',30,3100} };
for k=1:numel(cells)
    lab=cells{k}{1}; fid=cells{k}{2}; seed=cells{k}{3};
    mask=string(T.Algorithm)==string(lab) & T.FunctionID==fid & T.Seed==seed;
    assert(nnz(mask)==1,'unexpected old row count');
    oldCost=T.BestCost(mask);
    st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'steerMode','none');
    if strcmp(lab,'A0-GWOonly'), st.ablateE=1; end
    job=struct('algorithm','SGWO_STEER','label',lab,'fid',fid,'D',50,'seed',seed, ...
        'maxFE',100000,'N',50,'useProbe',true,'state',st);
    new=runner_sgwo(job);
    dc=abs(new.BestCost-oldCost);
    fprintf('  %-11s F%-3d s%d: old=%.12g new=%.12g d=%.3g\n',lab,fid,seed,oldCost,new.BestCost,dc);
    assert(dc<=1e-9*max(1,abs(oldCost)),'BestCost not reproduced');
    assert(new.Evaluations==100000,'FE mismatch');
end
fprintf('test_reuse_steer_baselines PASS: ablcore A2/A0 scalars reproduced by SGWO_STEER(none).\n');
end
