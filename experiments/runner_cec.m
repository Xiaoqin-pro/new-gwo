function result=runner_cec(job)
%RUNNER_CEC  One independent run: (algorithm, function, D, seed) -> record.
%   Designed for +overnight/runBatch4.m (parfor, exactly 4 local workers).
%
%   Protocol (identical to the audited historical batches so that results can
%   be paired with the audited baseline CSVs in data/reference/):
%     initSeed   = 261013000 + fid*10000 + seed
%     searchSeed = initSeed + 1000000
%     initial pool = -100 + 200*rand(50,D) after rng(initSeed,'twister');
%     every algorithm consumes the first N rows of that pool.
%
%   True-FE audit: every objective call passes through an EvalProbe that
%   counts evaluations independently of the algorithm; the run FAILS if the
%   algorithm's own counter disagrees with the probe.
%
%   job fields: algorithm, fid, D, seed, maxFE, N,
%               state (struct, optional per-run overrides),
%               useProbe (default true)
%   Algorithms: GWO, ANGWO, IGWO (read-only external), HIDMS-PSO, HCLPSO,
%   DMS-PSO, SAQ-CSO, SPSO-2011, HPSO-TVAC, CLPSO (read-only external).

persistent readyPaths
cfg=newgwo_config();
if isempty(readyPaths)
    addpath(fullfile(cfg.root,'src'));
    addpath(fullfile(cfg.root,'experiments'));
    addpath(cfg.cecDir);
    addpath(fullfile(cfg.wolfDir,'src'));            % IGWO (audited, read-only)
    addpath(genpath(fullfile(cfg.saqDir,'src')));    % strong baselines (read-only)
    addpath(fullfile(cfg.saqDir,'CEC2017_8Algorithm_30Seed')); % SPSO native mex
    addpath(fullfile(cfg.root,'src'),'-begin');      % our files win name conflicts
    readyPaths=true;
end
cd(cfg.cecDir);   % the CEC MEX opens "input_data/..." relative to the CWD

fid=job.fid; D=job.D; budget=job.maxFE; N=job.N;
job.seedInit=261013000+fid*10000+job.seed;
% Search-seed convention per audited batch family (both families share the SAME
% init pool, so cross-family pairing stays valid; see reports/baseline_audit.md):
%   wolf-pack family (GWO, IGWO, ANGWO):   searchSeed = seed + 1000000
%   9.29 family (strong PSO/CSO baselines): searchSeed = initSeed + 1000000
switch job.algorithm
    case {'GWO','ANGWO','IGWO'}
        job.seedSearch=job.seed+1000000;
    otherwise
        job.seedSearch=job.seedInit+1000000;
end
rng(job.seedInit,'twister');
pool=-100+200*rand(50,D);
if N>50
    pool=[pool; -100+200*rand(N-50,D)]; %#ok<AGROW>
end
state=struct('initialPopulation',pool(1:N,:), ...
    'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
    'maxEvaluations',budget);
if isfield(job,'state') && ~isempty(job.state)
    fn=fieldnames(job.state);
    for k=1:numel(fn)
        % job struct arrays pad absent fields with []; never let an empty
        % padding value shadow a real setting.
        if ~isempty(job.state.(fn{k})), state.(fn{k})=job.state.(fn{k}); end
    end
end

useProbe=true;
if isfield(job,'useProbe'), useProbe=logical(job.useProbe); end
probe=[];
fraw=@(x)CEC2017Function(x,fid);
if useProbe
    probe=EvalProbe(state.lowerBound,state.upperBound,budget,job.seed+51,5,200);
    f=@(x)probe.evaluate(fraw,x);
    state.probe=probe;   % ANGWO reuses the same archive for its decisions
else
    f=fraw;
end

t0=tic;
switch job.algorithm
    case 'GWO'
        [Best,T,info]=GWO(f,state,[],N,job.seedSearch);
    case 'ANGWO'
        [Best,T,info]=ANGWO(f,state,[],N,job.seedSearch);
    case 'IGWO'
        [Best,T,info]=IGWO(f,state,[],N,job.seedSearch);
    case 'HIDMS-PSO'
        [Best,T,info]=HIDMS_PSO_CEC(f,state,[],N,job.seedSearch);
    case 'HCLPSO'
        [Best,T,info]=HCLPSO_CEC_AuthorSource(f,state,[],N,job.seedSearch);
    case 'DMS-PSO'
        [Best,T,info]=DMS_PSO_SIS_CEC(f,state,[],N,job.seedSearch);
    case 'SAQ-CSO'
        state.ablationVariant='Full';
        [Best,T,info]=SAQ_CSO_AblationVariant(f,state,[],N,job.seedSearch);
    case 'SPSO-2011'
        [Best,T,info]=SPSO2011_CEC(f,state,[],N,job.seedSearch);
    case 'HPSO-TVAC'
        [Best,T,info]=HPSO_TVAC_CEC(f,state,[],N,job.seedSearch);
    case 'CLPSO'
        [Best,T,info]=CLPSO_CEC_AuthorSource(f,state,[],N,job.seedSearch);
    otherwise
        error('runner_cec:unknownAlgorithm','Unknown algorithm: %s',job.algorithm);
end
seconds=toc(t0);

% ---- true-FE audit ----
if useProbe
    assert(info.Evaluations==probe.fe, ...
        'runner_cec:FEaudit','FE mismatch: algorithm=%d probe=%d',info.Evaluations,probe.fe);
    assert(probe.fe==budget,'runner_cec:Budget','Expected %d FE, probe counted %d.',budget,probe.fe);
else
    assert(info.Evaluations==budget,'runner_cec:Budget','Expected %d FE, got %d.',budget,info.Evaluations);
end
assert(abs(T(end)-Best.Cost)<=1e-9*max(1,abs(Best.Cost)),'runner_cec:TraceEnd','T(end) ~= Best.Cost.');

% ---- trace metrics ----
W=max(50,round(0.01*budget));
M=trace_metrics(T,budget,W);

% ---- novelty metrics ----
NV=noveltyStats(probe,W,budget,T);

% ---- decimated trace for storage (500 log-spaced points) ----
idx=unique(round(logspace(0,log10(budget),500)));
idx=idx(idx>=1 & idx<=budget);

if isfield(info,'Rounds'), rounds=info.Rounds; else, rounds=NaN; end
if isfield(info,'NCandidateGenerated'), ncg=info.NCandidateGenerated; else, ncg=NaN; end
if useProbe, ndist=probe.nDistanceOps; else, ndist=NaN; end
if useProbe, pfe=probe.fe; else, pfe=budget; end

if isfield(job,'label') && ~isempty(job.label), label=job.label; else, label=job.algorithm; end
result=struct('Algorithm',label,'Family',job.algorithm,'FunctionID',fid,'D',D,'Seed',job.seed, ...
    'Status','ok','Message','', ...
    'BestCost',Best.Cost,'BestVector',Best.Vector, ...
    'Evaluations',info.Evaluations,'ProbeFE',pfe, ...
    'Rounds',rounds,'Seconds',seconds, ...
    'NCandidateGenerated',ncg,'NDistanceOps',ndist, ...
    'SearchSeed',job.seedSearch,'InitSeed',job.seedInit, ...
    'Metrics',M,'Novelty',NV, ...
    'TraceFE',idx,'Trace',T(idx));
end

% ==================== helpers ====================
function NV=noveltyStats(probe,W,budget,T)
%NOVELTYSTATS  预注册的新颖度指标（全部来自 EvalProbe 的抽样记录）。
%   NovelRate          : 采样评价中新颖度 >= tau 的比例（tau=1% 对角线）。
%   UsefulNovelRate    : 每次 global-best 改善回溯 W 个真实评价，把窗口内
%                        最近的一个"新颖采样"记一次 credit（一对一，不重复
%                        计功）；比例 = 被记功新颖采样数 / 新颖采样数。
%   StrictNovelImprove : 本身触发 global-best 改善的新颖采样数。
NV=struct('Mean',NaN,'Median',NaN,'NSamples',0,'NovelRate',NaN, ...
    'UsefulNovelRate',NaN,'StrictNovelImprove',NaN, ...
    'NovRateQ',nan(1,4),'WindowMean',nan(1,100),'WindowNovRate',nan(1,100));
if isempty(probe) || isempty(probe.novVal), return; end
nv=probe.novVal; nfe=probe.novFe;
tau=0.01;
NV.NSamples=numel(nv);
NV.Mean=mean(nv); NV.Median=median(nv);
novel=nv>=tau;
NV.NovelRate=mean(novel);
impr=find(T(2:end)<T(1:end-1))+1;
NV.StrictNovelImprove=sum(novel & ismember(nfe,impr));
used=false(size(nv));
for k=1:numel(impr)
    im=impr(k);
    cand=find(novel & nfe>=im-W & nfe<im);
    if ~isempty(cand), used(cand(end))=true; end
end
if any(novel), NV.UsefulNovelRate=sum(used)/sum(novel); else, NV.UsefulNovelRate=NaN; end
q=floor(linspace(1,budget+1,5));
for k=1:4
    sel=nfe>=q(k) & nfe<q(k+1);
    if any(sel), NV.NovRateQ(k)=mean(nv(sel)>=tau); end
end
edges=round(linspace(1,budget+1,101));
for w=1:100
    sel=nfe>=edges(w) & nfe<edges(w+1);
    if any(sel)
        NV.WindowMean(w)=mean(nv(sel));
        NV.WindowNovRate(w)=mean(nv(sel)>=tau);
    end
end
end


