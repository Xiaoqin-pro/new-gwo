% DEMOFOURWORKERS: infrastructure-only smoke test (NOT GWO research result).
% From the starter root: addpath(pwd); run('examples/demoFourWorkers.m')
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
pool = overnight.ensureFourWorkers();
assert(pool.NumWorkers == 4);
jobs = repmat(struct('id',0,'seed',0,'maxFE',200,'D',8,'requireFullBudget',true),1,8);
for j = 1:numel(jobs)
    jobs(j).id = j;
    jobs(j).seed = 42000+j;
end
outDir = fullfile(root,'output','parallel_smoke');
summary = overnight.runBatch4(jobs,@overnight.demoRun,outDir);
disp(summary);
assert(summary.nSuccess==8,'4-worker smoke did not complete successfully.');
fprintf('Verified 4-worker infrastructure, not algorithm performance.\n');
