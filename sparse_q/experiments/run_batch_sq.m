function out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt)
%RUN_BATCH_SQ  sparse_q 分支的 4-worker 批量驱动（恰好 4 worker，禁止串行降级）。
%   out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt)
%     algs  : {'SGWO','ANGWO','GWO'} 中的任意组合（ANGWO/GWO 为冻结只读对照）
%     opt   : states（与 algs 对齐的 state 覆盖 cell）、labels、useProbe、
%             resume（续跑目录）
%   机制同父工程 run_batch_new：独立 job 原子落盘、失败留痕、
%   overnight.runBatch4 断点续跑；本分支结果写入 sparse_q/results/。
if nargin<7, opt=struct(); end
cfg=newgwo_config();
sqRoot=fullfile(cfg.root,'sparse_q');
addpath(fullfile(sqRoot,'src'),fullfile(sqRoot,'experiments'),fullfile(sqRoot,'tests'),cfg.root);

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
    outDir=fullfile(sqRoot,'results',sprintf('%s_%s',tag,stamp));
end
if ~exist(outDir,'dir'), mkdir(outDir); end

h=struct();
h.SGWO=fileSha256(fullfile(sqRoot,'src','SGWO.m'));
if exist(fullfile(sqRoot,'src','SGWO_ECPS.m'),'file')
    h.SGWO_ECPS=fileSha256(fullfile(sqRoot,'src','SGWO_ECPS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_TRPS.m'),'file')
    h.SGWO_TRPS=fileSha256(fullfile(sqRoot,'src','SGWO_TRPS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_VGA.m'),'file')
    h.SGWO_VGA=fileSha256(fullfile(sqRoot,'src','SGWO_VGA.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_NPAR.m'),'file')
    h.SGWO_NPAR=fileSha256(fullfile(sqRoot,'src','SGWO_NPAR.m'));
end
h.runner_sgwo=fileSha256(fullfile(sqRoot,'experiments','runner_sgwo.m'));
h.ANGWO_frozen=fileSha256(fullfile(cfg.root,'src','ANGWO.m'));
h.GWO_frozen=fileSha256(fullfile(cfg.root,'src','GWO.m'));
provenance=struct('tag',tag,'algs',{algs},'labels',{labels},'funcs',funcs,'seeds',seeds, ...
    'D',D,'maxFE',maxFE,'useProbe',useProbe,'hashes',h,'stamp',datestr(now,'yyyymmdd_HHMMSS'));
save(fullfile(outDir,'provenance.mat'),'provenance');

fprintf('[run_batch_sq] %s: %d alg x %d fn x %d seeds = %d runs\n',tag,nA,nF,nS,nA*nF*nS);
summary=overnight.runBatch4(jobs,@runner_sgwo,outDir);
out=struct('outDir',outDir,'summary',summary);
collect_sq(outDir);
fprintf('[run_batch_sq] results: %s\n',outDir);
end

function N=algorithmPopulation(name)
switch name
    case {'HIDMS-PSO','SPSO-2011'}
        N=40;
    case 'DMS-PSO'
        N=30;
    case 'CLPSO'
        N=50;   % 主表统一协议 N=50（N=40 为作者原设置版本，已存档不再使用）
    otherwise
        N=50;
end
end
