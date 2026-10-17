function result = realRunner_ADAPTER_TEMPLATE(job)
% REPLACE THIS TEMPLATE ONLY AFTER LOCATING THE REAL CEC AND BASELINE FILES.
% Copy into your new project as actual runner fn with an appropriate name.
% job should include: algorithm, fid, D, seedInit, seedSearch, maxFE.
%
% persistent pathReady
% if isempty(pathReady)
%     addpath(...your new src folder...); addpath(...your CEC wrapper...);
%     pathReady=true;
% end
% rng(job.seedInit,'twister');
% initPool = ...; % documented fair init policy
% rng(job.seedSearch,'twister');
% [Best,trace,info] = fe_checked_algorithm(...);
% assert(info.Evaluations==job.maxFE);
% result = struct('BestCost',Best.Cost,'Evaluations',info.Evaluations, ...
%     'Trace',trace,'Algorithm',job.algorithm,'FunctionID',job.fid,...
%     'D',job.D,'Seed',job.seedSearch);
error('NEW_GWO:AdapterNotConfigured', ...
      'Connect real CEC2017 and source-audited baseline adapters before running.');
result=struct(); %#ok<NASGU>
end
