function audit_final_sample(batchDir)
%AUDIT_FINAL_SAMPLE  对正式批做抽样逐位复核：选 (S-star/S1/S3p/S5p/B1) 各 2 个
%(function,seed)，用当前代码重跑并与批内记录比较（要求逐位一致）。
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'),fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'));
cfg=struct('root',root);
checks={
 'S-star',1,3001; 'S-star',13,3007;
 'S1-pool38',6,3003; 'S1-pool38',24,3012;
 'S3p-q25',9,3005; 'S3p-q25',18,3020;
 'S5p-q',4,3009; 'S5p-q',13,3025;
 'B1-dense-sync',1,3002; 'B1-dense-sync',24,3018;
 };
% load batch csv
T=readtable(fullfile(batchDir,'runs.csv'),'TextType','string');
bad=0;
for i=1:size(checks,1)
    lab=checks{i,1}; fid=checks{i,2}; sd=checks{i,3};
    job=struct('algorithm','SGWO','label',lab,'fid',fid,'D',50,'seed',sd,'maxFE',100000,'N',50);
    switch lab
        case 'S-star', job.state=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
        case 'S1-pool38', job.state=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','random');
        case 'S3p-q25', job.state=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','strat','g1Share',2/3,'stratG1','random','stratE','random','quotaPolicy','fixed','quotaFixed',0.25);
        case 'S5p-q', job.state=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','strat','g1Share',2/3,'stratG1','random','stratE','random','quotaPolicy','q');
        case 'B1-dense-sync', job.state=struct('mode','dense-sync');
    end
    res=runner_sgwo(job);
    row=T(T.Algorithm==lab & T.FunctionID==fid & T.Seed==sd,:);
    errNow=res.BestCost-100*fid;   % CEC2017: error = cost - 100*fid
    d=abs(errNow-row.FinalError)/max(1,abs(row.FinalError));
    ok=d<1e-12;
    fprintf('  %-14s F%02d s%d: ours=%.10g batch=%.10g rel=%.2e %s\n',lab,fid,sd,errNow,row.FinalError,d,tern(ok,'OK','MISMATCH'));
    bad=bad+~ok;
end
fprintf('audit_final_sample: %d mismatches\n',bad);
assert(bad==0,'sample audit failed');
end
function s=tern(c,a,b)
if c, s=a; else, s=b; end
end

