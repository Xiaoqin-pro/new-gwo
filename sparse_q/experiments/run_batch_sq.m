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
if exist(fullfile(sqRoot,'src','SGWO_CAGL.m'),'file')
    h.SGWO_CAGL=fileSha256(fullfile(sqRoot,'src','SGWO_CAGL.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_TSD.m'),'file')
    h.SGWO_TSD=fileSha256(fullfile(sqRoot,'src','SGWO_TSD.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_WLR.m'),'file')
    h.SGWO_WLR=fileSha256(fullfile(sqRoot,'src','SGWO_WLR.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_RGI.m'),'file')
    h.SGWO_RGI=fileSha256(fullfile(sqRoot,'src','SGWO_RGI.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_BGR.m'),'file')
    h.SGWO_BGR=fileSha256(fullfile(sqRoot,'src','SGWO_BGR.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_NEL.m'),'file')
    h.SGWO_NEL=fileSha256(fullfile(sqRoot,'src','SGWO_NEL.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_REF.m'),'file')
    h.SGWO_REF=fileSha256(fullfile(sqRoot,'src','SGWO_REF.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_PCSS.m'),'file')
    h.SGWO_PCSS=fileSha256(fullfile(sqRoot,'src','SGWO_PCSS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_LLT.m'),'file')
    h.SGWO_LLT=fileSha256(fullfile(sqRoot,'src','SGWO_LLT.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_RED.m'),'file')
    h.SGWO_RED=fileSha256(fullfile(sqRoot,'src','SGWO_RED.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_STEER.m'),'file')
    h.SGWO_STEER=fileSha256(fullfile(sqRoot,'src','SGWO_STEER.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_STEER3.m'),'file')
    h.SGWO_STEER3=fileSha256(fullfile(sqRoot,'src','SGWO_STEER3.m'));
end
if exist(fullfile(sqRoot,'src','LSHADE_CEC.m'),'file')
    h.LSHADE_CEC=fileSha256(fullfile(sqRoot,'src','LSHADE_CEC.m'));
end
if exist(fullfile(sqRoot,'src','NELSHADE.m'),'file')
    h.NELSHADE=fileSha256(fullfile(sqRoot,'src','NELSHADE.m'));
end
if exist(fullfile(sqRoot,'src','NMLSHADE.m'),'file')
    h.NMLSHADE=fileSha256(fullfile(sqRoot,'src','NMLSHADE.m'));
end
if exist(fullfile(sqRoot,'src','SLSHADE.m'),'file')
    h.SLSHADE=fileSha256(fullfile(sqRoot,'src','SLSHADE.m'));
end
if exist(fullfile(sqRoot,'src','ASLSHADE.m'),'file')
    h.ASLSHADE=fileSha256(fullfile(sqRoot,'src','ASLSHADE.m'));
end
if exist(fullfile(sqRoot,'src','CMAES_CEC.m'),'file')
    h.CMAES_CEC=fileSha256(fullfile(sqRoot,'src','CMAES_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA_DE_CEC.m'),'file')
    h.CMA_DE_CEC=fileSha256(fullfile(sqRoot,'src','CMA_DE_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA_TAIL_CEC.m'),'file')
    h.CMA_TAIL_CEC=fileSha256(fullfile(sqRoot,'src','CMA_TAIL_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA_JSO_CEC.m'),'file')
    h.CMA_JSO_CEC=fileSha256(fullfile(sqRoot,'src','CMA_JSO_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA_GATED_CEC.m'),'file')
    h.CMA_GATED_CEC=fileSha256(fullfile(sqRoot,'src','CMA_GATED_CEC.m'));
end
if exist(fullfile(sqRoot,'src','SPACMA_CEC.m'),'file')
    h.SPACMA_CEC=fileSha256(fullfile(sqRoot,'src','SPACMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PORTFOLIO_CEC.m'),'file')
    h.PORTFOLIO_CEC=fileSha256(fullfile(sqRoot,'src','PORTFOLIO_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PILOT_CEC.m'),'file')
    h.PILOT_CEC=fileSha256(fullfile(sqRoot,'src','PILOT_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PILOT_RESUME_CEC.m'),'file')
    h.PILOT_RESUME_CEC=fileSha256(fullfile(sqRoot,'src','PILOT_RESUME_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PILOT_ASYM_CEC.m'),'file')
    h.PILOT_ASYM_CEC=fileSha256(fullfile(sqRoot,'src','PILOT_ASYM_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA_LS_CEC.m'),'file')
    h.CMA_LS_CEC=fileSha256(fullfile(sqRoot,'src','CMA_LS_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMA2_CEC.m'),'file')
    h.CMA2_CEC=fileSha256(fullfile(sqRoot,'src','CMA2_CEC.m'));
end
if exist(fullfile(sqRoot,'src','ADAPT_CORE_CEC.m'),'file')
    h.ADAPT_CORE_CEC=fileSha256(fullfile(sqRoot,'src','ADAPT_CORE_CEC.m'));
end
if exist(fullfile(sqRoot,'src','DAR_CMA_CEC.m'),'file')
    h.DAR_CMA_CEC=fileSha256(fullfile(sqRoot,'src','DAR_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','MNC_CMA_CEC.m'),'file')
    h.MNC_CMA_CEC=fileSha256(fullfile(sqRoot,'src','MNC_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','ALCMA_CEC.m'),'file')
    h.ALCMA_CEC=fileSha256(fullfile(sqRoot,'src','ALCMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','IPOP_CMA_CEC.m'),'file')
    h.IPOP_CMA_CEC=fileSha256(fullfile(sqRoot,'src','IPOP_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','GWO_CMA_CEC.m'),'file')
    h.GWO_CMA_CEC=fileSha256(fullfile(sqRoot,'src','GWO_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','MM_CMA_CEC.m'),'file')
    h.MM_CMA_CEC=fileSha256(fullfile(sqRoot,'src','MM_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','SCMA_CEC.m'),'file')
    h.SCMA_CEC=fileSha256(fullfile(sqRoot,'src','SCMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','LS_CMA_CEC.m'),'file')
    h.LS_CMA_CEC=fileSha256(fullfile(sqRoot,'src','LS_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','ACMA_CEC.m'),'file')
    h.ACMA_CEC=fileSha256(fullfile(sqRoot,'src','ACMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','HCCMA_CEC.m'),'file')
    h.HCCMA_CEC=fileSha256(fullfile(sqRoot,'src','HCCMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','REHEAT_CMA_CEC.m'),'file')
    h.REHEAT_CMA_CEC=fileSha256(fullfile(sqRoot,'src','REHEAT_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','LSHADE_CML_CEC.m'),'file')
    h.LSHADE_CML_CEC=fileSha256(fullfile(sqRoot,'src','LSHADE_CML_CEC.m'));
end
if exist(fullfile(sqRoot,'src','LSHADE_CNEPSIN_CEC.m'),'file')
    h.LSHADE_CNEPSIN_CEC=fileSha256(fullfile(sqRoot,'src','LSHADE_CNEPSIN_CEC.m'));
end
if exist(fullfile(sqRoot,'src','jSO_CEC.m'),'file')
    h.jSO_CEC=fileSha256(fullfile(sqRoot,'src','jSO_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PORTFOLIO2_CEC.m'),'file')
    h.PORTFOLIO2_CEC=fileSha256(fullfile(sqRoot,'src','PORTFOLIO2_CEC.m'));
end
if exist(fullfile(sqRoot,'src','JSO_CMA_CEC.m'),'file')
    h.JSO_CMA_CEC=fileSha256(fullfile(sqRoot,'src','JSO_CMA_CEC.m'));
end
if exist(fullfile(sqRoot,'src','PILOT_JSO_CEC.m'),'file')
    h.PILOT_JSO_CEC=fileSha256(fullfile(sqRoot,'src','PILOT_JSO_CEC.m'));
end
if exist(fullfile(sqRoot,'src','CMAES_RESUME.m'),'file')
    h.CMAES_RESUME=fileSha256(fullfile(sqRoot,'src','CMAES_RESUME.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_VFA.m'),'file')
    h.SGWO_VFA=fileSha256(fullfile(sqRoot,'src','SGWO_VFA.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DLH.m'),'file')
    h.SGWO_DLH=fileSha256(fullfile(sqRoot,'src','SGWO_DLH.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_SALS.m'),'file')
    h.SGWO_SALS=fileSha256(fullfile(sqRoot,'src','SGWO_SALS.m'));
end
if exist(fullfile(sqRoot,'src','salsRebuildPos.m'),'file')
    h.salsRebuildPos=fileSha256(fullfile(sqRoot,'src','salsRebuildPos.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_ESTEER.m'),'file')
    h.SGWO_ESTEER=fileSha256(fullfile(sqRoot,'src','SGWO_ESTEER.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_MSE.m'),'file')
    h.SGWO_MSE=fileSha256(fullfile(sqRoot,'src','SGWO_MSE.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_IDC.m'),'file')
    h.SGWO_IDC=fileSha256(fullfile(sqRoot,'src','SGWO_IDC.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DIAG.m'),'file')
    h.SGWO_DIAG=fileSha256(fullfile(sqRoot,'src','SGWO_DIAG.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_EMIX.m'),'file')
    h.SGWO_EMIX=fileSha256(fullfile(sqRoot,'src','SGWO_EMIX.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_MIS.m'),'file')
    h.SGWO_MIS=fileSha256(fullfile(sqRoot,'src','SGWO_MIS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_CROWD.m'),'file')
    h.SGWO_CROWD=fileSha256(fullfile(sqRoot,'src','SGWO_CROWD.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_KNOB.m'),'file')
    h.SGWO_KNOB=fileSha256(fullfile(sqRoot,'src','SGWO_KNOB.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_LAST.m'),'file')
    h.SGWO_LAST=fileSha256(fullfile(sqRoot,'src','SGWO_LAST.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_NULL.m'),'file')
    h.SGWO_NULL=fileSha256(fullfile(sqRoot,'src','SGWO_NULL.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_PAIR.m'),'file')
    h.SGWO_PAIR=fileSha256(fullfile(sqRoot,'src','SGWO_PAIR.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DSEP.m'),'file')
    h.SGWO_DSEP=fileSha256(fullfile(sqRoot,'src','SGWO_DSEP.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_GAAS.m'),'file')
    h.SGWO_GAAS=fileSha256(fullfile(sqRoot,'src','SGWO_GAAS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_SHA.m'),'file')
    h.SGWO_SHA=fileSha256(fullfile(sqRoot,'src','SGWO_SHA.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_RSE.m'),'file')
    h.SGWO_RSE=fileSha256(fullfile(sqRoot,'src','SGWO_RSE.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_AGLM.m'),'file')
    h.SGWO_AGLM=fileSha256(fullfile(sqRoot,'src','SGWO_AGLM.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_HDR.m'),'file')
    h.SGWO_HDR=fileSha256(fullfile(sqRoot,'src','SGWO_HDR.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_CDE.m'),'file')
    h.SGWO_CDE=fileSha256(fullfile(sqRoot,'src','SGWO_CDE.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DRG.m'),'file')
    h.SGWO_DRG=fileSha256(fullfile(sqRoot,'src','SGWO_DRG.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_CSS.m'),'file')
    h.SGWO_CSS=fileSha256(fullfile(sqRoot,'src','SGWO_CSS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_GHS.m'),'file')
    h.SGWO_GHS=fileSha256(fullfile(sqRoot,'src','SGWO_GHS.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DWG.m'),'file')
    h.SGWO_DWG=fileSha256(fullfile(sqRoot,'src','SGWO_DWG.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_DSE.m'),'file')
    h.SGWO_DSE=fileSha256(fullfile(sqRoot,'src','SGWO_DSE.m'));
end
if exist(fullfile(sqRoot,'src','SGWO_TSDR.m'),'file')
    h.SGWO_TSDR=fileSha256(fullfile(sqRoot,'src','SGWO_TSDR.m'));
end
for nm={'MENGWO_CEC','IAGWO_CEC'}
    fp=fullfile(sqRoot,'src',[nm{1} '.m']);
    if exist(fp,'file'), h.(nm{1})=fileSha256(fp); end
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
    case 'SPACMA100'
        N=100;
    case 'SGWO100'
        N=100;
    case 'SPACMA200'
        N=200;
    case 'SPACMA400'
        N=400;
    case 'SPACMA600'
        N=600;
    case 'SPACMA900'
        N=900;
    otherwise
        N=50;
end
end

