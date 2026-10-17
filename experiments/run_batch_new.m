function out=run_batch_new(tag,algs,funcs,seeds,D,maxFE,opt)
%RUN_BATCH_NEW  Four-worker batch over independent (algorithm,function,seed) jobs.
%   out=run_batch_new(tag,algs,funcs,seeds,D,maxFE,opt)
%
%   algs   : cellstr of algorithm families, e.g. {'GWO','ANGWO'} (runner_cec)
%   funcs  : CEC2017 function ids, e.g. [1 3:30]
%   seeds  : independent seeds, e.g. 3001:3030
%   opt    : optional struct with fields
%              states  cell array aligned with algs (per-run state overrides)
%              labels  cell array aligned with algs (display names; default algs)
%              useProbe logical (default true)
%              resume  existing batch directory to continue
%
%   Parallelism: exactly 4 local workers (overnight.ensureFourWorkers);
%   NEVER a serial fallback. One job = one independent run; each finished run
%   is written to results/<tag>_<stamp>/runs/run_%05d.mat immediately, so a
%   crashed batch can be resumed with the same call plus opt.resume.
if nargin<7, opt=struct(); end
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(cfg.root,'experiments'),cfg.root);

if ~iscell(algs), algs=cellstr(algs); end
funcs=funcs(:)'; seeds=seeds(:)';
nA=numel(algs);
states=cell(1,nA); if isfield(opt,'states') && ~isempty(opt.states), states=opt.states; end
labels=algs; if isfield(opt,'labels') && ~isempty(opt.labels), labels=opt.labels; end
useProbe=true; if isfield(opt,'useProbe'), useProbe=logical(opt.useProbe); end

nF=numel(funcs); nS=numel(seeds);
jobs=struct('algorithm',{},'label',{},'fid',{},'D',{},'seed',{},'maxFE',{},'N',{},'state',{},'useProbe',{});
k=0;
for fi=1:nF
    for si=1:nS
        for ai=1:nA
            k=k+1;
            name=algs{ai};
            N=algorithmPopulation(name);
            st=struct();
            if ~isempty(states{ai}), st=states{ai}; end
            jobs(k)=struct('algorithm',name,'label',labels{ai},'fid',funcs(fi), ...
                'D',D,'seed',seeds(si),'maxFE',maxFE,'N',N,'state',st,'useProbe',useProbe);
        end
    end
end

if isfield(opt,'resume') && ~isempty(opt.resume)
    outDir=char(opt.resume);
else
    stamp=datestr(now,'yyyymmdd_HHMMSS');
    outDir=fullfile(cfg.root,'results',sprintf('%s_%s',tag,stamp));
end
if ~exist(outDir,'dir'), mkdir(outDir); end

h=struct();
h.GWO=fileSha256(fullfile(cfg.root,'src','GWO.m'));
h.ANGWO=fileSha256(fullfile(cfg.root,'src','ANGWO.m'));
h.EvalProbe=fileSha256(fullfile(cfg.root,'src','EvalProbe.m'));
h.runner_cec=fileSha256(fullfile(cfg.root,'experiments','runner_cec.m'));
provenance=struct('tag',tag,'algs',{algs},'labels',{labels},'funcs',funcs,'seeds',seeds, ...
    'D',D,'maxFE',maxFE,'useProbe',useProbe,'hashes',h,'stamp',datestr(now,'yyyymmdd_HHMMSS'));
save(fullfile(outDir,'provenance.mat'),'provenance');

fprintf('[run_batch_new] %s: %d alg x %d fn x %d seeds = %d runs\n',tag,nA,nF,nS,nA*nF*nS);
summary=overnight.runBatch4(jobs,@runner_cec,outDir);
out=struct('outDir',outDir,'summary',summary);
collect_results(outDir);
fprintf('[run_batch_new] results: %s\n',outDir);
end

function N=algorithmPopulation(name)
switch name
    case {'HIDMS-PSO','SPSO-2011'}
        N=40;
    case 'DMS-PSO'
        N=30;
    otherwise
        N=50;
end
end

