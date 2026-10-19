function out=test_d100_resume_failure()
%TEST_D100_RESUME_FAILURE  Harness audit: failure recording + resume behaviour.
%   Runs a small scratch batch containing (a) two valid low-budget jobs and
%   (b) one job with an unknown algorithm, then re-runs the same manifest and
%   checks that completed jobs are skipped while the failed job is retried and
%   recorded with an explicit error message.
here=fileparts(mfilename('fullpath')); sqRoot=fileparts(here); root=fileparts(sqRoot);
addpath(fullfile(root,'src'), fullfile(root,'data','cec2017'));
addpath(fullfile(sqRoot,'src'), fullfile(sqRoot,'experiments'), sqRoot, here);

stamp=datestr(now,'yyyymmdd_HHMMSS');
outDir=fullfile(sqRoot,'results',sprintf('_harness_test_%s',stamp));
jobs(1)=struct('algorithm','SGWO','label','VAST-GWO','fid',1,'D',100,'seed',4998, ...
               'maxFE',3000,'N',50,'state',struct('mode','sparse','K',10,'screenPolicy','random','nG2',12,'nE',38),'useProbe',true);
jobs(2)=struct('algorithm','GWO','label','GWO','fid',1,'D',100,'seed',4998, ...
               'maxFE',3000,'N',50,'state',struct(),'useProbe',true);
jobs(3)=struct('algorithm','NOSUCH','label','INVALID','fid',1,'D',100,'seed',4998, ...
               'maxFE',3000,'N',50,'state',struct(),'useProbe',true);

fprintf('\n--- pass 1 (expect 2 ok, 1 failed) ---\n');
s1=overnight.runBatch4(jobs,@runner_sgwo,outDir);
disp(s1);
f1=load(fullfile(outDir,'runs','run_00003.mat'),'record');
fprintf('failed record status=%s error=%s\n', f1.record.status, f1.record.error);
assert(s1.nSuccess==2 && s1.nFailed==1,'expect 2 ok / 1 failed');

fprintf('\n--- pass 2 (resume: expect 0 pending for ok jobs, failed retried) ---\n');
t0=tic; s2=overnight.runBatch4(jobs,@runner_sgwo,outDir); el=toc(t0);
disp(s2);
fprintf('second pass wall clock %.1f s\n', el);
assert(s2.nSuccess==2 && s2.nFailed==1,'resume counts wrong');
assert(el < 120,'resume re-ran completed jobs (took %.1f s)');

tmp=dir(fullfile(outDir,'runs','*_tmp.mat'));
assert(isempty(tmp),'temporary files left behind');
fprintf('no *_tmp.mat leftovers; total files=%d\n', numel(dir(fullfile(outDir,'runs','*.mat'))));
out=struct('outDir',outDir,'s1',s1,'s2',s2,'elapsed2',el);
end
