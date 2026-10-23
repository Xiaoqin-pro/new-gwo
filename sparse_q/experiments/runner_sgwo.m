function result=runner_sgwo(job)
%RUNNER_SGWO  One independent run for the sparse_q branch -> record.
%   Same protocol as the frozen project (init-seed pool, FE probe, 4 workers):
%     initSeed   = 261013000 + fid*10000 + seed
%     searchSeed = seed + 1000000
%     initial pool = -100 + 200*rand(50,D) after rng(initSeed,'twister')
%   Algorithms: SGWO (new, sparse_q/src), ANGWO / GWO (frozen, read-only calls).
%   job fields: algorithm, label, fid, D, seed, maxFE, N, state (SGWO overrides),
%               useProbe (default true)
persistent readyPaths
cfg=newgwo_config();
sqRoot=fullfile(cfg.root,'sparse_q');
if isempty(readyPaths)
    addpath(fullfile(cfg.root,'src'));            % frozen EvalProbe/trace_metrics/GWO/ANGWO
    addpath(fullfile(cfg.root,'experiments'));    % (read-only scaffold)
    addpath(fullfile(cfg.root,'data','cec2017'));
    addpath(fullfile(sqRoot,'src'));
    addpath(fullfile(cfg.wolfDir,'src'));            % IGWO（审计只读对照）
    addpath(fullfile(sqRoot,'src'),'-begin');     % our new algorithm wins conflicts
    readyPaths=true;
end
cd(cfg.cecDir);

fid=job.fid; D=job.D; budget=job.maxFE; N=job.N;
job.seedInit=261013000+fid*10000+job.seed;
job.seedSearch=job.seed+1000000;
rng(job.seedInit,'twister');
pool=-100+200*rand(50,D);
if N>50, pool=[pool; -100+200*rand(N-50,D)]; end
state=struct('initialPopulation',pool(1:N,:), ...
    'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
    'maxEvaluations',budget);
if isfield(job,'state') && ~isempty(job.state)
    fn=fieldnames(job.state);
    for k=1:numel(fn)
        if ~isempty(job.state.(fn{k})), state.(fn{k})=job.state.(fn{k}); end
    end
end
if isfield(job,'fid'), state.functionID=job.fid; end

useProbe=true; if isfield(job,'useProbe'), useProbe=logical(job.useProbe); end
probe=[]; fraw=@(x)CEC2017Function(x,fid);
if useProbe
    probe=EvalProbe(state.lowerBound,state.upperBound,budget,job.seed+51,5,200);
    f=@(x)probe.evaluate(fraw,x);
    state.probe=probe;
else
    f=fraw;
end

t0=tic;
switch job.algorithm
    case 'SGWO'
        [Best,T,info]=SGWO(f,state,[],N,job.seedSearch);
    case 'SGWOAB'
        [Best,T,info]=SGWO_ABLATION(f,state,[],N,job.seedSearch);
    case 'SGWO_ECPS'
        [Best,T,info]=SGWO_ECPS(f,state,[],N,job.seedSearch);
    case 'SGWO_TRPS'
        [Best,T,info]=SGWO_TRPS(f,state,[],N,job.seedSearch);
    case 'SGWO_VGA'
        [Best,T,info]=SGWO_VGA(f,state,[],N,job.seedSearch);
    case 'SGWO_NPAR'
        [Best,T,info]=SGWO_NPAR(f,state,[],N,job.seedSearch);
    case 'SGWO_CAGL'
        [Best,T,info]=SGWO_CAGL(f,state,[],N,job.seedSearch);
    case 'SGWO_TSD'
        [Best,T,info]=SGWO_TSD(f,state,[],N,job.seedSearch);
    case 'SGWO_WLR'
        [Best,T,info]=SGWO_WLR(f,state,[],N,job.seedSearch);
    case 'SGWO_RGI'
        [Best,T,info]=SGWO_RGI(f,state,[],N,job.seedSearch);
    case 'SGWO_BGR'
        [Best,T,info]=SGWO_BGR(f,state,[],N,job.seedSearch);
    case 'SGWO_NEL'
        [Best,T,info]=SGWO_NEL(f,state,[],N,job.seedSearch);
    case 'SGWO_REF'
        [Best,T,info]=SGWO_REF(f,state,[],N,job.seedSearch);
    case 'SGWO_PCSS'
        [Best,T,info]=SGWO_PCSS(f,state,[],N,job.seedSearch);
    case 'SGWO_LLT'
        [Best,T,info]=SGWO_LLT(f,state,[],N,job.seedSearch);
    case 'SGWO_RED'
        [Best,T,info]=SGWO_RED(f,state,[],N,job.seedSearch);
    case 'SGWO_STEER'
        [Best,T,info]=SGWO_STEER(f,state,[],N,job.seedSearch);
    case 'SGWO_STEER3'
        [Best,T,info]=SGWO_STEER3(f,state,[],N,job.seedSearch);
    case 'SGWO_ESTEER'
        [Best,T,info]=SGWO_ESTEER(f,state,[],N,job.seedSearch);
    case 'SGWO_MSE'
        [Best,T,info]=SGWO_MSE(f,state,[],N,job.seedSearch);
    case 'SGWO_IDC'
        [Best,T,info]=SGWO_IDC(f,state,[],N,job.seedSearch);
    case 'SGWO_DIAG'
        [Best,T,info]=SGWO_DIAG(f,state,[],N,job.seedSearch);
    case 'SGWO_EMIX'
        [Best,T,info]=SGWO_EMIX(f,state,[],N,job.seedSearch);
    case 'SGWO_MIS'
        [Best,T,info]=SGWO_MIS(f,state,[],N,job.seedSearch);
    case 'SGWO_CROWD'
        [Best,T,info]=SGWO_CROWD(f,state,[],N,job.seedSearch);
    case 'SGWO_KNOB'
        [Best,T,info]=SGWO_KNOB(f,state,[],N,job.seedSearch);
    case 'SGWO_LAST'
        [Best,T,info]=SGWO_LAST(f,state,[],N,job.seedSearch);
    case 'SGWO_NULL'
        [Best,T,info]=SGWO_NULL(f,state,[],N,job.seedSearch);
    case 'SGWO_PAIR'
        [Best,T,info]=SGWO_PAIR(f,state,[],N,job.seedSearch);
    case 'SGWO_DSEP'
        [Best,T,info]=SGWO_DSEP(f,state,[],N,job.seedSearch);
    case 'SGWO_GAAS'
        [Best,T,info]=SGWO_GAAS(f,state,[],N,job.seedSearch);
    case 'SGWO_SHA'
        [Best,T,info]=SGWO_SHA(f,state,[],N,job.seedSearch);
    case 'SGWO_RSE'
        [Best,T,info]=SGWO_RSE(f,state,[],N,job.seedSearch);
    case 'SGWO_AGLM'
        [Best,T,info]=SGWO_AGLM(f,state,[],N,job.seedSearch);
    case 'SGWO_HDR'
        [Best,T,info]=SGWO_HDR(f,state,[],N,job.seedSearch);
    case 'SGWO_CDE'
        [Best,T,info]=SGWO_CDE(f,state,[],N,job.seedSearch);
    case 'SGWO_DRG'
        [Best,T,info]=SGWO_DRG(f,state,[],N,job.seedSearch);
    case 'SGWO_CSS'
        [Best,T,info]=SGWO_CSS(f,state,[],N,job.seedSearch);
    case 'SGWO_GHS'
        [Best,T,info]=SGWO_GHS(f,state,[],N,job.seedSearch);
    case 'SGWO_DWG'
        [Best,T,info]=SGWO_DWG(f,state,[],N,job.seedSearch);
    case 'LSHADE'
        [Best,T,info]=LSHADE_CEC(f,state,[],N,job.seedSearch);
    case 'NELSHADE'
        [Best,T,info]=NELSHADE(f,state,[],N,job.seedSearch);
    case 'NMLSHADE'
        [Best,T,info]=NMLSHADE(f,state,[],N,job.seedSearch);
    case 'SLSHADE'
        [Best,T,info]=SLSHADE(f,state,[],N,job.seedSearch);
    case 'ASLSHADE'
        [Best,T,info]=ASLSHADE(f,state,[],N,job.seedSearch);
    case 'CMAES'
        [Best,T,info]=CMAES_CEC(f,state,[],N,job.seedSearch);
    case 'PORTFOLIO'
        [Best,T,info]=PORTFOLIO_CEC(f,state,[],N,job.seedSearch);
    case 'PILOT'
        [Best,T,info]=PILOT_CEC(f,state,[],N,job.seedSearch);
    case 'PILOT_RESUME'
        [Best,T,info]=PILOT_RESUME_CEC(f,state,[],N,job.seedSearch);
    case 'PILOT_ASYM'
        [Best,T,info]=PILOT_ASYM_CEC(f,state,[],N,job.seedSearch);
    case 'CMA_LS'
        [Best,T,info]=CMA_LS_CEC(f,state,[],N,job.seedSearch);
    case 'CMA2'
        [Best,T,info]=CMA2_CEC(f,state,[],N,job.seedSearch);
    case 'ADAPT_CORE'
        [Best,T,info]=ADAPT_CORE_CEC(f,state,[],N,job.seedSearch);
    case 'SGWO_HYBRID'
        [Best,T,info]=SGWO_HYBRID(f,state,[],N,job.seedSearch);
    case 'SGWO_HYBRID2'
        [Best,T,info]=SGWO_HYBRID2(f,state,[],N,job.seedSearch);
    case 'SGWO_VFA'
        [Best,T,info]=SGWO_VFA(f,state,[],N,job.seedSearch);
    case 'SGWO_DLH'
        [Best,T,info]=SGWO_DLH(f,state,[],N,job.seedSearch);
    case 'SGWO_SALS'
        [Best,T,info]=SGWO_SALS(f,state,[],N,job.seedSearch);
    case 'SGWO_DSE'
        [Best,T,info]=SGWO_DSE(f,state,[],N,job.seedSearch);
    case 'SGWO_TSDR'
        [Best,T,info]=SGWO_TSDR(f,state,[],N,job.seedSearch);
    case 'ANGWO'
        [Best,T,info]=ANGWO(f,state,[],N,job.seedSearch);   % frozen, read-only
    case 'DMSGWO'
        [Best,T,info]=DMSGWO_CEC(f,state,[],N,job.seedSearch);
    case 'RLGWO'
        [Best,T,info]=RLGWO_CEC(f,state,[],N,job.seedSearch);
    case 'HAGWO'
        [Best,T,info]=HAGWO_CEC(f,state,[],N,job.seedSearch);
    case 'AOGWO'
        [Best,T,info]=AOGWO_CEC(f,state,[],N,job.seedSearch);
    case 'EDGWO'
        [Best,T,info]=EDGWO_CEC(f,state,[],N,job.seedSearch);
    case 'PSO'
        [Best,T,info]=PSO_CEC(f,state,[],N,job.seedSearch);
    case 'CLPSO'
        [Best,T,info]=CLPSO_CEC(f,state,[],N,job.seedSearch);
    case 'IGWO'
        [Best,T,info]=IGWO(f,state,[],N,job.seedSearch);
    case 'GWO'
        [Best,T,info]=GWO(f,state,[],N,job.seedSearch);     % frozen, read-only
    otherwise
        error('runner_sgwo:unknownAlgorithm','Unknown algorithm: %s',job.algorithm);
end
seconds=toc(t0);

if useProbe
    assert(info.Evaluations==probe.fe,'runner_sgwo:FEaudit','FE mismatch: alg=%d probe=%d',info.Evaluations,probe.fe);
    assert(probe.fe==budget,'runner_sgwo:Budget','Expected %d FE, probe counted %d.',budget,probe.fe);
else
    assert(info.Evaluations==budget,'runner_sgwo:Budget','Expected %d FE, got %d.',budget,info.Evaluations);
end
assert(abs(T(end)-Best.Cost)<=1e-9*max(1,abs(Best.Cost)),'runner_sgwo:TraceEnd','T(end) ~= Best.Cost.');

W=max(50,round(0.01*budget));
M=trace_metrics(T,budget,W);
NV=noveltyStats(probe,W,budget,T);
idx=unique(round(logspace(0,log10(budget),500)));
idx=idx(idx>=1 & idx<=budget);

% ---- SGWO-specific summary ----
S=struct('K',NaN,'NCandidateGenerated',NaN,'NDistanceOps',NaN,'NArchiveInserts',NaN, ...
    'ArchiveSize',NaN,'QuotaAct1Pct',NaN,'QuotaAct2Pct',NaN,'QuotaAct3Pct',NaN, ...
    'ImpCnt',nan(1,4),'ImpMag',nan(1,4), ...
    'ECPSOn',NaN,'ECPSMode',"",'ECPSWindow',NaN,'ECPSActionCounts',nan(1,4), ...
    'ECPSSuccCounts',nan(1,4),'ECPSEvalCounts',nan(1,4),'ECPSProbMean',nan(1,4),'ECPSEntropyMean',NaN, ...
    'ECPSGBCounts',nan(1,4),'ECPSGBSuccCounts',nan(1,4),'ECPSArcCounts',nan(1,4),'ECPSArcSuccCounts',nan(1,4),'ECPSMagSum',nan(1,4), ...
    'VGAOn',NaN,'VGAMode',"",'VGAEvalCount',NaN,'VGASuccCount',NaN,'VGAAcceptCount',NaN, ...
    'VGAAcceptRate',NaN,'VGASuccessRate',NaN,'VGAPReplaceMean',NaN, ...
    'NparOn',NaN,'NparMode',"",'NparFullBetter',NaN,'NparFarEvents',NaN,'NparChangedTarget',NaN, ...
    'NparEligibleEvents',NaN,'NparFallbackEvents',NaN,'NparActualReplacements',NaN,'NparRandomDifferent',NaN, ...
    'NparNNEvents',NaN,'NparMeanNNBefore',NaN,'NparMeanNNGlobal',NaN,'NparMeanNNPair',NaN, ...
    'CaglOn',NaN,'CaglMode',"",'CaglRounds',NaN,'CaglCollapseRounds',NaN,'CaglCollapseRate',NaN, ...
    'CaglEligibleRounds',NaN,'CaglEligibleShare',NaN,'CaglEligibleCentersMean',NaN, ...
    'CaglGuidedCandidates',NaN,'CaglDirectionEvents',NaN,'CaglMeanNormDiff',NaN,'CaglMeanCos',NaN, ...
    'CaglDirChanged10',NaN,'CaglRandomSelections',NaN, ...
    'TsdOn',NaN,'TsdMode',"",'TsdG1Eval',NaN,'TsdG1Split',NaN,'TsdStateSplitRate',NaN, ...
    'TsdEEval',NaN,'TsdECursorOnly',NaN,'TsdCursorOnlyRate',NaN,'TsdOEEval',NaN, ...
    'TsdOECursorOnly',NaN,'TsdOECursorOnlyRate',NaN,'TsdProtectUpdates',NaN, ...
    'TsdMeanGapDist',NaN,'TsdMeanGapFit',NaN,'TsdMaxGapDist',NaN, ...
    'TsdrOn',NaN,'TsdrMode',"",'TsdrG1Eval',NaN,'TsdrTriggers',NaN,'TsdrTriggerRate',NaN, ...
    'TsdrRecoveries',NaN, ...
    'TsdrEarly',NaN,'TsdrMid',NaN,'TsdrLate',NaN,'TsdrArcEvents',NaN,'TsdrArcDistMean',NaN, ...
    'TsdrArcCoveredRate',NaN,'TsdrRecDistMean',NaN,'TsdrRecArcMean',NaN,'TsdrRecCoveredRate',NaN,'TsdrTrace',[], ...
    'WlrOn',NaN,'WlrMode',"",'WlrMacroGens',NaN,'WlrLeaderChanges',NaN,'WlrGenWithChange',NaN, ...
    'WlrChangeRate',NaN,'WlrEvaluatedG1',NaN,'WlrStaleCount',NaN,'WlrStaleRate',NaN, ...
    'WlrMeanStaleDist',NaN,'WlrMedianStaleDist',NaN,'WlrP90StaleDist',NaN, ...
    'RgiOn',NaN,'RgiMode',"",'RgiTriggers',NaN,'RgiEvaluated',NaN,'RgiEvaluatedRate',NaN, ...
    'BgrOn',NaN,'BgrMode',"",'BgrG1Cand',NaN,'BgrOutCand',NaN,'BgrOutCandRate',NaN, ...
    'BgrOutCoord',NaN,'BgrTotalCoord',NaN,'BgrOutCoordRate',NaN,'BgrClipDistMean',NaN, ...
    'BgrClipDistMedian',NaN,'BgrClipDistP90',NaN,'BgrEarlyRate',NaN,'BgrMidRate',NaN,'BgrLateRate',NaN, ...
    'NelOn',NaN,'NelMode',"",'NelCandidates',NaN,'NelSelected',NaN, ...
    'RefOn',NaN,'RefMode',"",'RefCandidates',NaN,'RefSelected',NaN, ...
    'PcssOn',NaN,'PcssMode',"",'PcssN',NaN,'PcssPred',[],'PcssTrue',[],'PcssFE',[],'PcssGen',[], ...
    'PcssGuideEval',NaN,'PcssGuideBetter',NaN,'PcssGuideRate',NaN,'PcssRandEval',NaN, ...
    'LltOn',NaN,'LltMode',"",'LltWindow',NaN,'LltLeaders',NaN,'LltRounds',NaN, ...
    'RedOn',NaN,'RedMode',"",'RedEps',NaN,'RedDraws',NaN,'RedRejects',NaN, ...
    'SteerOn',NaN,'SteerMode',"",'SteerProb',NaN,'SteerLambda',NaN,'SteerTriggers',NaN, ...
    'DsAuditOn',NaN,'DaArcImpCnt',NaN,'DaArcGapMax',NaN,'DaDualFE',NaN,'DaFirstDualFE',NaN,'DaTau',NaN, ...
    'DseOn',NaN,'DseMode',"",'DseRho',NaN,'DseTau',NaN,'DseCap',NaN,'DseGateGens',NaN, ...
    'VfaOn',NaN,'VfaMode',"",'VfaCap',NaN,'VfaAdmits',NaN,'VfaSize',NaN,'VfaSizeMax',NaN, ...
    'DlhOn',NaN,'DlhMode',"",'DlhN',NaN,'DlhNeighMean',NaN,'DlhNeighZeroFrac',NaN, ...
    'SalsOn',NaN,'SalsMode',"",'SalsGens',NaN,'SalsNMean',NaN,'SalsDispBMean',NaN,'SalsDispCMean',NaN, ...
    'SalsShiftBMean',NaN,'SalsShiftCMean',NaN,'SalsStratFrac',NaN, ...
    'DlhDegFrac',NaN,'DlhDispMed',NaN,'DlhVsGwoMed',NaN,'DlhVsEMed',NaN,'DlhGwoVsEMed',NaN, ...
    'VfaSepEMed',NaN,'VfaDistEMed',NaN,'VfaGapMed',NaN,'VfaEvalNear',NaN,'VfaEvalTot',NaN, ...
    'VfaImpNear',NaN,'VfaImpTot',NaN, ...
    'DseUsed',NaN,'DseUsedFrac',NaN,'DseFirstFE',NaN,'DsePopAcc',NaN,'DseArcAcc',NaN, ...
    'DsePopAccRate',NaN,'DseArcAccRate',NaN, ...
    'SteerApplied',NaN,'SteerRate',NaN, ...
    'EsteerOn',NaN,'EsteerMode',"",'EsteerGen',NaN,'EsteerTrig',NaN,'EsteerTrigRate',NaN,'EsteerStepMean',NaN, ...
    'MseOn',NaN,'MseMode',"",'MseCand',nan(1,3),'MseEval',nan(1,3),'MseEvalRate',nan(1,3),'MseDispMean',nan(1,3),'MseClipRate',nan(1,3), ...
    'MseClipFracMean',nan(1,3),'MseSurvMean',nan(1,3),'MseDispIntMean',nan(1,3), ...
    'IdcStableID',NaN,'IdcResetOnRefresh',NaN,'IdcAudit',NaN,'IdcCredTotal',NaN,'IdcWrong',NaN,'IdcWrongRate',NaN,'IdcStale',NaN,'IdcStaleRate',NaN,'IdcDropped',NaN,'IdcRefresh',NaN,'IdcLeakEvents',NaN,'IdcLeakRate',NaN,'IdcLeakMass',NaN,'IdcLeakMassRatio',NaN, ...
    'DiagEval',nan(10,4),'DiagGB',nan(10,4),'DiagArc',nan(10,4),'DiagPop',nan(10,4), ...
    'DiagLifeEval',nan(1,6),'DiagLifeN',NaN,'DiagZeroEval',NaN,'DiagEvalSum',NaN,'DiagQual',nan(10,1), ...
    'EShellShare',NaN,'EShellPer',NaN, ...
    'MisIslands',NaN,'MisMigrateOn',NaN,'MisMigrateEvery',NaN,'MisMigrations',NaN,'MisIslandBest',nan(1,5), ...
    'ExtReplace',"",'ExtRepN',NaN,'ExtRepDistMean',NaN, ...
    'FillerSteer',NaN,'FillerSteerN',NaN,'FillerSteerApplied',NaN,'EvalOrder',"", ...
    'InitMode',"",'CentreCoverage',NaN, ...
    'NullOffset',NaN, ...
    'PairMode',"",'PairN',NaN,'PairEvalC',nan(1,3),'PairGBC',nan(1,3),'PairArcC',nan(1,3),'PairGBRate',nan(1,3),'PairArcRate',nan(1,3), ...
    'DSepRef',"",'DSepBirth',NaN,'DSepSpanMean',NaN,'DSepSpanLast',NaN, ...
    'GaasMode',"",'GaasShellN',NaN,'GaasLineN',NaN,'GaasSimplexN',NaN,'GaasEval',nan(1,3),'GaasGB',nan(1,3),'GaasArc',nan(1,3), ...
    'ShaMode',"",'ShaEvals',NaN,'ShaSuccess',NaN,'ShaTrace',[],'ShaFactorMean',NaN,'ShaFactorMin',NaN,'ShaFactorMax',NaN,'ShaAUpPct',NaN,'ShaADownPct',NaN, ...
    'RseMode',"",'RseEval',nan(1,4),'RseGB',nan(1,4),'RseArc',nan(1,4), ...
    'MixMode',"",'MixOnGens',NaN,'MixAppliedGens',NaN,'MixAppliedRate',NaN,'MixDistMean',NaN, ...
    'DeMode',"",'DeStartFE',NaN,'DeAppliedGens',NaN,'DeAppliedCandidates',NaN, ...
    'CdeMode',"",'CdeApplied',NaN, ...
    'DrgMode',"",'DrgExploreN',NaN,'DrgApplied',NaN, ...
    'CssMode',"",'CssN',NaN,'CssDims',NaN,'CssPhaseFrac',NaN,'CssSelect',"",'CssApplied',NaN, ...
    'HybMode',"",'HybN',NaN,'ShadeApplied',NaN,'ShadeSuccess',NaN,'ShadeArchiveSize',NaN, ...
    'DwgMode',"",'DwgN1',NaN,'DwgApplied',NaN,'DwgSuccess',NaN, ...
    'RedDupN',NaN,'RedDistN',NaN,'RedDupImpRate',NaN,'RedDistImpRate',NaN, ...
    'RedDupGBRate',NaN,'RedDistGBRate',NaN,'RedDupArcRate',NaN,'RedDistArcRate',NaN, ...
    'RedSelDupRate',NaN,'RedDminMedian',NaN, ...
    'LltLocalNeGlobalRate',NaN,'LltDispMean',NaN,'LltDispMedian',NaN,'LltDispP90',NaN, ...
    'LltDupSelectedRate',NaN,'LltG1NNMedian',NaN,'LltPhaseDisp',nan(1,3),'LltDispTrace',[], ...
    'PcssRandBetter',NaN,'PcssRandRate',NaN,'PcssFallbackGens',NaN,'PcssGuidedGens',NaN, ...
    'RgiRestarts',NaN,'RgiEvaluatedRestarts',NaN,'RgiRestartRate',NaN,'RgiTrace',[], ...
    'RewardMean',NaN,'GBWindowPct',NaN,'QTable',nan(6,3),'QActionCounts',nan(1,3),'QStateVisits',nan(1,6));
S.EcoMode=""; S.EcoOn=NaN; S.EcoAdaptive=NaN; S.EcoNicheBankSize=NaN; S.EcoNicheBankMax=NaN;
S.MigMode=""; S.MigOn=NaN; S.MigPeriodic=NaN; S.MigBankSize=NaN; S.MigBankMax=NaN; S.MigHistSize=NaN; S.MigProgressWindow=NaN; S.MigPlateauTol=NaN; S.MigPeriodicEvery=NaN; S.MigFrac=NaN; S.MigTriggers=NaN; S.MigRounds=NaN; S.MigMigrants=NaN; S.MigBetter=NaN;
S.ScreenPolicy=""; S.SparseK=NaN; S.ScreenNearFrac=NaN; S.TrialsGenerated=NaN; S.TrialsSelected=NaN; S.NearSelected=NaN; S.FarSelected=NaN;
S.ScreenMode=""; S.KWindow=NaN; S.K10Count=NaN; S.K25Count=NaN; S.K50Count=NaN; S.K10MeanReward=NaN; S.K25MeanReward=NaN; S.K50MeanReward=NaN;
S.PilotRule=""; S.Winner=""; S.PilotFE=NaN; S.FinalFE=NaN; S.CMAESPilot=NaN; S.LSHADEPilot=NaN; S.PilotInitialBest=NaN; S.PilotCMARel=NaN; S.PilotLSRel=NaN; S.FinalCoreCost=NaN; S.PilotBest=NaN;
S.AdaptSwitched=NaN; S.AdaptSwitchFE=NaN; S.AdaptBlockFE=NaN; S.AdaptTol=NaN; S.AdaptFirstCMA=NaN;
S.EcoNicheAdmits=NaN; S.EcoNicheReplaces=NaN; S.EcoBankEval=NaN; S.EcoGens=NaN; S.EcoStagGens=NaN;
S.EcoNicheSrcGen=NaN; S.EcoNicheEval=NaN; S.EcoBaseEval=NaN; S.EcoNicheSuccess=NaN; S.EcoBaseSuccess=NaN;
S.EcoNicheEvalRate=NaN; S.EcoNicheSuccessRate=NaN; S.EcoBaseSuccessRate=NaN; S.EcoPFinal=NaN; S.EcoPMean=NaN; S.EcoPMax=NaN;
if isfield(info,'QuotaTrace')   % 仅 SGWO 系列具备该字段（IGWO 的 info 里也有 K，不能用作守卫）
    qt=info.QuotaTrace;
    S.K=info.K;
    S.NCandidateGenerated=info.NCandidateGenerated;
    S.NDistanceOps=info.NDistanceOps;
    S.NArchiveInserts=info.NArchiveInserts;
    S.ArchiveSize=info.ArchiveSize;
    na=numel(info.QActionCounts);
    S.QActionCounts=info.QActionCounts; S.QStateVisits=info.QStateVisits; S.QTable=info.QTable;
    if isfield(info,'QuotaTrace'), S.QuotaTrace=info.QuotaTrace; end
    if isfield(info,'ImpCnt'), S.ImpCnt=info.ImpCnt; S.ImpMag=info.ImpMag; end
    ecpsNames={'ECPSOn','ECPSMode','ECPSWindow','ECPSActionCounts','ECPSSuccCounts','ECPSEvalCounts','ECPSProbMean','ECPSEntropyMean','ECPSGBCounts','ECPSGBSuccCounts','ECPSArcCounts','ECPSArcSuccCounts','ECPSMagSum','VGAOn','VGAMode','VGAEvalCount','VGASuccCount','VGAAcceptCount','VGAAcceptRate','VGASuccessRate','VGAPReplaceMean','NparOn','NparMode','NparFullBetter','NparFarEvents','NparChangedTarget','NparEligibleEvents','NparFallbackEvents','NparActualReplacements','NparRandomDifferent','NparNNEvents','NparMeanNNBefore','NparMeanNNGlobal','NparMeanNNPair','CaglOn','CaglMode','CaglRounds','CaglCollapseRounds','CaglCollapseRate','CaglEligibleRounds','CaglEligibleShare','CaglEligibleCentersMean','CaglGuidedCandidates','CaglDirectionEvents','CaglMeanNormDiff','CaglMeanCos','CaglDirChanged10','CaglRandomSelections','TsdOn','TsdMode','TsdG1Eval','TsdG1Split','TsdStateSplitRate','TsdEEval','TsdECursorOnly','TsdCursorOnlyRate','TsdOEEval','TsdOECursorOnly','TsdOECursorOnlyRate','TsdProtectUpdates','TsdMeanGapDist','TsdMeanGapFit','TsdMaxGapDist', ...
        'TsdrOn','TsdrMode','TsdrG1Eval','TsdrTriggers','TsdrTriggerRate','TsdrRecoveries','TsdrEarly','TsdrMid','TsdrLate', ...
        'TsdrArcEvents','TsdrArcDistMean','TsdrArcCoveredRate','TsdrRecDistMean','TsdrRecArcMean','TsdrRecCoveredRate','TsdrTrace', ...
        'WlrOn','WlrMode','WlrMacroGens','WlrLeaderChanges','WlrGenWithChange','WlrChangeRate', ...
        'WlrEvaluatedG1','WlrStaleCount','WlrStaleRate','WlrMeanStaleDist','WlrMedianStaleDist','WlrP90StaleDist', ...
        'RgiOn','RgiMode','RgiTriggers','RgiEvaluated','RgiEvaluatedRate','RgiRestarts','RgiEvaluatedRestarts','RgiRestartRate','RgiTrace', ...
        'BgrOn','BgrMode','BgrG1Cand','BgrOutCand','BgrOutCandRate','BgrOutCoord','BgrTotalCoord','BgrOutCoordRate', ...
        'BgrClipDistMean','BgrClipDistMedian','BgrClipDistP90','BgrEarlyRate','BgrMidRate','BgrLateRate', ...
        'NelOn','NelMode','NelCandidates','NelSelected','RefOn','RefMode','RefCandidates','RefSelected','PcssOn','PcssMode','PcssN','PcssPred','PcssTrue','PcssFE','PcssGen', ...
        'PcssGuideEval','PcssGuideBetter','PcssGuideRate','PcssRandEval','PcssRandBetter','PcssRandRate','PcssFallbackGens','PcssGuidedGens', ...
        'LltOn','LltMode','LltWindow','LltLeaders','LltRounds','LltLocalNeGlobalRate','LltDispMean','LltDispMedian','LltDispP90','LltDupSelectedRate','LltG1NNMedian','LltPhaseDisp','LltDispTrace', ...
        'RedOn','RedMode','RedEps','RedDraws','RedRejects','RedDupN','RedDistN','RedDupImpRate','RedDistImpRate','RedDupGBRate','RedDistGBRate','RedDupArcRate','RedDistArcRate','RedSelDupRate','RedDminMedian', ...
        'SteerOn','SteerMode','SteerProb','SteerLambda','SteerTriggers','SteerApplied','SteerRate', ...
        'EsteerOn','EsteerMode','EsteerGen','EsteerTrig','EsteerTrigRate','EsteerStepMean', ...
        'MseOn','MseMode','MseCand','MseEval','MseEvalRate','MseDispMean','MseClipRate', ...
        'MseClipFracMean','MseSurvMean','MseDispIntMean', ...
        'IdcStableID','IdcResetOnRefresh','IdcAudit','IdcCredTotal','IdcWrong','IdcWrongRate','IdcStale','IdcStaleRate','IdcDropped','IdcRefresh','IdcLeakEvents','IdcLeakRate','IdcLeakMass','IdcLeakMassRatio', ...
        'DiagEval','DiagGB','DiagArc','DiagPop','DiagLifeEval','DiagLifeN','DiagZeroEval','DiagEvalSum','DiagQual', ...
        'EShellShare','EShellPer', ...
        'MisIslands','MisMigrateOn','MisMigrateEvery','MisMigrations','MisIslandBest', ...
        'ExtReplace','ExtRepN','ExtRepDistMean', ...
        'FillerSteer','FillerSteerN','FillerSteerApplied','EvalOrder', ...
        'InitMode','CentreCoverage', ...
        'NullOffset', ...
        'PairMode','PairN','PairEvalC','PairGBC','PairArcC','PairGBRate','PairArcRate', ...
        'DSepRef','DSepBirth','DSepSpanMean','DSepSpanLast', ...
        'GaasMode','GaasShellN','GaasLineN','GaasSimplexN','GaasEval','GaasGB','GaasArc', ...
        'ShaMode','ShaEvals','ShaSuccess','ShaTrace','ShaFactorMean','ShaFactorMin','ShaFactorMax','ShaAUpPct','ShaADownPct', ...
        'RseMode','RseEval','RseGB','RseArc', ...
        'MixMode','MixOnGens','MixAppliedGens','MixAppliedRate','MixDistMean', ...
        'DeMode','DeStartFE','DeAppliedGens','DeAppliedCandidates', ...
        'CdeMode','CdeApplied', ...
        'DrgMode','DrgExploreN','DrgApplied', ...
        'CssMode','CssN','CssDims','CssPhaseFrac','CssSelect','CssApplied', ...
        'HybMode','HybN','ShadeApplied','ShadeSuccess','ShadeArchiveSize', ...
        'EcoMode','EcoOn','EcoAdaptive','EcoNicheBankSize','EcoNicheBankMax','EcoNicheAdmits','EcoNicheReplaces','EcoBankEval','EcoGens','EcoStagGens', ...
        'EcoNicheSrcGen','EcoNicheEval','EcoBaseEval','EcoNicheSuccess','EcoBaseSuccess','EcoNicheEvalRate','EcoNicheSuccessRate','EcoBaseSuccessRate','EcoPFinal','EcoPMean','EcoPMax', ...
        'DwgMode','DwgN1','DwgApplied','DwgSuccess', ...
        'DsAuditOn','DaArcImpCnt','DaArcGapMax','DaDualFE','DaFirstDualFE','DaTau', ...
        'DseOn','DseMode','DseRho','DseTau','DseCap','DseGateGens','DseUsed','DseUsedFrac','DseFirstFE','DsePopAcc','DseArcAcc','DsePopAccRate','DseArcAccRate', ...
        'VfaOn','VfaMode','VfaCap','VfaAdmits','VfaSize','VfaSizeMax','VfaSepEMed','VfaDistEMed','VfaGapMed','VfaEvalNear','VfaEvalTot','VfaImpNear','VfaImpTot', ...
        'DlhOn','DlhMode','DlhN','DlhNeighMean','DlhNeighZeroFrac','DlhDegFrac','DlhDispMed','DlhVsGwoMed','DlhVsEMed','DlhGwoVsEMed', ...
        'SalsOn','SalsMode','SalsGens','SalsNMean','SalsDispBMean','SalsDispCMean','SalsShiftBMean','SalsShiftCMean','SalsStratFrac'};
    for ii=1:numel(ecpsNames)
        if isfield(info,ecpsNames{ii}), S.(ecpsNames{ii})=info.(ecpsNames{ii}); end
    end
    if na>=3 && ~isempty(qt)
        nz=qt(:,3)>0;
        if any(nz)
            acts=qt(nz,3);
            S.QuotaAct1Pct=mean(acts==1); S.QuotaAct2Pct=mean(acts==2); S.QuotaAct3Pct=mean(acts==3);
        end
    end
    if ~isempty(qt)
        S.RewardMean=mean(qt(:,5));
        S.GBWindowPct=mean(qt(:,6)>0);
    end
end

ecoNames={'EcoMode','EcoOn','EcoAdaptive','EcoNicheBankSize','EcoNicheBankMax','EcoNicheAdmits','EcoNicheReplaces','EcoBankEval','EcoGens','EcoStagGens','EcoNicheSrcGen','EcoNicheEval','EcoBaseEval','EcoNicheSuccess','EcoBaseSuccess','EcoNicheEvalRate','EcoNicheSuccessRate','EcoBaseSuccessRate','EcoPFinal','EcoPMean','EcoPMax'};
for ii=1:numel(ecoNames)
    if isfield(info,ecoNames{ii}), S.(ecoNames{ii})=info.(ecoNames{ii}); end
end

migNames={'MigMode','MigOn','MigPeriodic','MigBankSize','MigBankMax','MigHistSize','MigProgressWindow','MigPlateauTol','MigPeriodicEvery','MigFrac','MigTriggers','MigRounds','MigMigrants','MigBetter'};
for ii=1:numel(migNames)
    if isfield(info,migNames{ii}), S.(migNames{ii})=info.(migNames{ii}); end
end

sNames={'ScreenPolicy','SparseK','ScreenNearFrac','TrialsGenerated','TrialsSelected','NearSelected','FarSelected'};
for ii=1:numel(sNames)
    if isfield(info,sNames{ii}), S.(sNames{ii})=info.(sNames{ii}); end
end
pNames={'PilotRule','Winner','PilotFE','FinalFE','CMAESPilot','LSHADEPilot','PilotInitialBest','PilotCMARel','PilotLSRel','FinalCoreCost','PilotBest'};
aNames={'Switched','SwitchFE','BlockFE','StagnationTol','FirstCMA'};
for ii=1:numel(aNames)
    if isfield(info,aNames{ii}), S.(['Adapt' aNames{ii}])=info.(aNames{ii}); end
end
for ii=1:numel(pNames)
    if isfield(info,pNames{ii}), S.(pNames{ii})=info.(pNames{ii}); end
end
if isfield(info,'KChoices')
    kc=info.KChoices(:)';
    for qi=1:min(3,numel(kc))
        nm=sprintf('K%d',kc(qi));
        if isfield(info,'KCounts') && qi<=numel(info.KCounts), S.([nm 'Count'])=info.KCounts(qi); end
        if isfield(info,'KMeanReward') && qi<=numel(info.KMeanReward), S.([nm 'MeanReward'])=info.KMeanReward(qi); end
    end
    S.KWindow=info.KWindow; S.ScreenMode=info.ScreenMode;
end

if isfield(job,'label') && ~isempty(job.label), label=job.label; else, label=job.algorithm; end
if isfield(info,'Rounds'), rounds=info.Rounds; else, rounds=NaN; end
if useProbe, pfe=probe.fe; ndist=probe.nDistanceOps; else, pfe=budget; ndist=NaN; end

result=struct('Algorithm',label,'Family',job.algorithm,'FunctionID',fid,'D',D,'Seed',job.seed, ...
    'Status','ok','Message','', ...
    'BestCost',Best.Cost,'BestVector',Best.Vector, ...
    'Evaluations',info.Evaluations,'ProbeFE',pfe, ...
    'Rounds',rounds,'Seconds',seconds, ...
    'NDistanceProbe',ndist, ...
    'SearchSeed',job.seedSearch,'InitSeed',job.seedInit, ...
    'Metrics',M,'Novelty',NV,'SGWO',S, ...
    'TraceFE',idx,'Trace',T(idx));
end

% ==================== helpers ====================
function NV=noveltyStats(probe,W,budget,T)
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
if any(novel), NV.UsefulNovelRate=sum(used)/sum(novel); end
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


