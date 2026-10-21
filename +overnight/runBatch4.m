function summary = runBatch4(jobs, runner, outDir)
%RUNBATCH4 Resume-safe four-worker evaluation orchestration.
% summary = overnight.runBatch4(jobs,@yourRunner,'results/batch_01')
% runner(job) must return scalar struct with BestCost and Evaluations fields.
% jobs must be a nonempty struct vector; one job = one independent run.
% All outputs are independent MAT files; failed runs are retained and retried.
% NOTE: This orchestrates jobs; it does not implement GWO or CEC itself.
assert(isstruct(jobs) && ~isempty(jobs),'Jobs must be nonempty struct vector.');
assert(isa(runner,'function_handle'),'Runner must be a function handle.');
if isstring(outDir), outDir=char(outDir); end
pool=overnight.ensureFourWorkers();
assert(pool.NumWorkers==4,'Use exactly 4 workers.');
if ~exist(outDir,'dir'), mkdir(outDir); end
runDir=fullfile(outDir,'runs');
if ~exist(runDir,'dir'), mkdir(runDir); end
manifest=fullfile(outDir,'manifest.mat');
if isfile(manifest)
    previous=load(manifest,'jobs');
    assert(isequaln(previous.jobs,jobs),'Resume manifest mismatch: jobs changed.');
else
    save(manifest,'jobs');
end
n=numel(jobs);
complete=false(1,n);
for k=1:n
    target=fullfile(runDir,sprintf('run_%05d.mat',k));
    if isfile(target)
        try
            a=load(target,'record');
            complete(k)=isfield(a,'record') && strcmp(a.record.status,'ok');
        catch
            complete(k)=false;
        end
    end
end
todo=find(~complete);
fprintf('[NEW-GWO] 4-worker pool; %d total; %d done; %d pending; output=%s\n',n,sum(complete),numel(todo),outDir);
% Each worker writes its own unique file to avoid writes to shared summary.
parfor jj=1:numel(todo)
    k=todo(jj);
    t=tic;
    record=struct('id',k,'status','failed','result',struct(), ...
                  'seconds',NaN,'error','');
    try
        res=runner(jobs(k));
        validateResult(res,jobs(k));
        record.result=res;
        record.status='ok';
    catch ME
        record.error=sprintf('%s: %s',ME.identifier,ME.message);
        try
            ef=fullfile(outDir,sprintf('error_%05d.txt',k));
            fid=fopen(ef,'w');
            fprintf(fid,'JOB %d\n%s\n',k,getReport(ME,'extended','hyperlinks','off'));
            fclose(fid);
        catch
        end
    end
    record.seconds=toc(t);
    % Helper function avoids MATLAB parfor workspace transparency restrictions.
    writeOne(runDir,k,record);
end
ok=0; bad=0; missing=0;
for k=1:n
    target=fullfile(runDir,sprintf('run_%05d.mat',k));
    if ~isfile(target), missing=missing+1; continue; end
    a=load(target,'record');
    if strcmp(a.record.status,'ok'), ok=ok+1; else, bad=bad+1; end
end
summary=struct('workers',4,'nJobs',n,'nSuccess',ok,'nFailed',bad, ...
               'nMissing',missing,'directory',outDir);
save(fullfile(outDir,'summary.mat'),'summary');
fprintf('[NEW-GWO] done=%d failed=%d missing=%d workers=4\n',ok,bad,missing);
end

function validateResult(res,job)
assert(isstruct(res) && isscalar(res),'Runner must return a scalar struct.');
assert(isfield(res,'BestCost') && isscalar(res.BestCost) && isfinite(res.BestCost), ...
    'Bad or missing BestCost.');
assert(isfield(res,'Evaluations') && isscalar(res.Evaluations) && ...
    isfinite(res.Evaluations) && res.Evaluations==floor(res.Evaluations), ...
    'Bad or missing true-Evaluation counter.');
if isfield(job,'maxFE')
    assert(res.Evaluations<=job.maxFE,'Exceeded true FE budget.');
    if isfield(job,'requireFullBudget') && job.requireFullBudget
        assert(res.Evaluations==job.maxFE,'Expected exact maxFE budget.');
    end
end
end

function writeOne(runDir,k,record)
file=fullfile(runDir,sprintf('run_%05d.mat',k));
tmp=fullfile(runDir,sprintf('run_%05d_tmp.mat',k));
save(tmp,'record','-v7');
[good,msg]=movefile(tmp,file,'f');
assert(good,'Could not save run %d: %s',k,msg);
end
