function pool = ensureFourWorkers()
%ENSUREFOURWORKERS Guarantee exactly 4 MATLAB local workers; NEVER fallback.
% Requires Parallel Computing Toolbox and enough local-worker entitlement.
assert(license('test','Distrib_Computing_Toolbox') == 1, ...
    'overnight:ParallelUnavailable', ...
    'Parallel Computing Toolbox is not licensed. No serial fallback.');
pool = gcp('nocreate');
if ~isempty(pool)
    if pool.NumWorkers == 4
        fprintf('[NEW-GWO] Reusing MATLAB pool with 4 workers.\n');
        return;
    end
    error('overnight:WrongExistingPool', ...
        ['Existing pool has %d workers; do not destroy a potentially ' ...
         'busy pool automatically. Close it explicitly, then retry ' ...
         'parpool(''local'',4).'],pool.NumWorkers);
end
pool = parpool('local',4);
assert(pool.NumWorkers==4,'overnight:WrongPoolSize', ...
    'Expected 4 local workers; got %d.',pool.NumWorkers);
fprintf('[NEW-GWO] Local parallel pool confirmed: %d workers.\n',pool.NumWorkers);
end
