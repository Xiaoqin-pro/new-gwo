function Tbl=collect_sq(outDir)
%COLLECT_SQ  把 sparse_q 批次目录展开为 runs.csv（含 SGWO 机制列）。
files=dir(fullfile(outDir,'runs','run_*.mat'));
assert(~isempty(files),'collect_sq:empty','No run_*.mat in %s',outDir);
n=numel(files);
rows=cell(n,1);
for i=1:n
    a=load(fullfile(files(i).folder,files(i).name),'record');
    r=a.record;
    row=emptyRow();
    row.RunID=r.id;
    if strcmp(r.status,'ok')
        res=r.result; M=res.Metrics; NV=res.Novelty; S=res.SGWO;
        row.Algorithm=string(res.Algorithm); row.Family=string(res.Family);
        row.FunctionID=res.FunctionID; row.D=res.D; row.Seed=res.Seed;
        row.Status="ok";
        row.BestCost=res.BestCost;
        row.FinalError=res.BestCost-100*res.FunctionID;
        row.Evaluations=res.Evaluations; row.ProbeFE=res.ProbeFE;
        row.Rounds=res.Rounds; row.Seconds=res.Seconds;
        row.NCandidateGenerated=S.NCandidateGenerated;
        row.NDistanceOps=S.NDistanceOps;
        row.NArchiveInserts=S.NArchiveInserts; row.ArchiveSize=S.ArchiveSize;
        if isfield(S,'ImpCnt')
            ic=S.ImpCnt; im=S.ImpMag;
        if isfield(S,'PcssOn') && ~isnan(S.PcssOn)
            row.PcssOn=S.PcssOn; row.PcssMode=S.PcssMode; row.PcssN=S.PcssN;
            if isfield(S,'PcssGuideEval')
                row.PcssGuideEval=S.PcssGuideEval; row.PcssGuideBetter=S.PcssGuideBetter; row.PcssGuideRate=S.PcssGuideRate;
                row.PcssRandEval=S.PcssRandEval; row.PcssRandBetter=S.PcssRandBetter; row.PcssRandRate=S.PcssRandRate;
                row.PcssFallbackGens=S.PcssFallbackGens; row.PcssGuidedGens=S.PcssGuidedGens;
            end
        end
        if isfield(S,'RefOn') && ~isnan(S.RefOn)
            row.RefOn=S.RefOn; row.RefMode=S.RefMode; row.RefCandidates=S.RefCandidates; row.RefSelected=S.RefSelected;
        end
        if isfield(S,'SalsOn') && ~isnan(S.SalsOn)
            row.SalsOn=S.SalsOn; row.SalsMode=S.SalsMode; row.SalsGens=S.SalsGens; row.SalsNMean=S.SalsNMean;
            row.SalsDispBMean=S.SalsDispBMean; row.SalsDispCMean=S.SalsDispCMean;
            row.SalsShiftBMean=S.SalsShiftBMean; row.SalsShiftCMean=S.SalsShiftCMean; row.SalsStratFrac=S.SalsStratFrac;
        end
        if isfield(S,'DlhOn') && ~isnan(S.DlhOn)
            row.DlhOn=S.DlhOn; row.DlhMode=S.DlhMode; row.DlhN=S.DlhN; row.DlhNeighMean=S.DlhNeighMean;
            row.DlhNeighZeroFrac=S.DlhNeighZeroFrac; row.DlhDegFrac=S.DlhDegFrac;
            row.DlhDispMed=S.DlhDispMed; row.DlhVsGwoMed=S.DlhVsGwoMed;
            row.DlhVsEMed=S.DlhVsEMed; row.DlhGwoVsEMed=S.DlhGwoVsEMed;
        end
        if isfield(S,'VfaOn') && ~isnan(S.VfaOn)
            row.VfaOn=S.VfaOn; row.VfaMode=S.VfaMode; row.VfaCap=S.VfaCap; row.VfaAdmits=S.VfaAdmits;
            row.VfaSize=S.VfaSize; row.VfaSizeMax=S.VfaSizeMax; row.VfaSepEMed=S.VfaSepEMed;
            row.VfaDistEMed=S.VfaDistEMed; row.VfaGapMed=S.VfaGapMed;
            row.VfaEvalNear=S.VfaEvalNear; row.VfaEvalTot=S.VfaEvalTot;
            row.VfaImpNear=S.VfaImpNear; row.VfaImpTot=S.VfaImpTot;
        end
        if isfield(S,'DseOn') && ~isnan(S.DseOn)
            row.DseOn=S.DseOn; row.DseMode=S.DseMode; row.DseRho=S.DseRho; row.DseTau=S.DseTau; row.DseCap=S.DseCap;
            row.DseGateGens=S.DseGateGens; row.DseUsed=S.DseUsed; row.DseUsedFrac=S.DseUsedFrac; row.DseFirstFE=S.DseFirstFE;
            row.DsePopAcc=S.DsePopAcc; row.DseArcAcc=S.DseArcAcc; row.DsePopAccRate=S.DsePopAccRate; row.DseArcAccRate=S.DseArcAccRate;
        end
        if isfield(S,'DsAuditOn') && ~isnan(S.DsAuditOn)
            row.DsAuditOn=S.DsAuditOn; row.DaArcImpCnt=S.DaArcImpCnt; row.DaArcGapMax=S.DaArcGapMax;
            row.DaDualFE=S.DaDualFE; row.DaFirstDualFE=S.DaFirstDualFE; row.DaTau=S.DaTau;
        end
        if isfield(S,'SteerOn') && ~isnan(S.SteerOn)
            row.SteerOn=S.SteerOn; row.SteerMode=S.SteerMode; row.SteerProb=S.SteerProb;
            row.SteerLambda=S.SteerLambda; row.SteerTriggers=S.SteerTriggers;
            row.SteerApplied=S.SteerApplied; row.SteerRate=S.SteerRate;
        end
        if isfield(S,'EsteerOn') && ~isnan(S.EsteerOn)
            row.EsteerOn=S.EsteerOn; row.EsteerMode=S.EsteerMode; row.EsteerGen=S.EsteerGen;
            row.EsteerTrig=S.EsteerTrig; row.EsteerTrigRate=S.EsteerTrigRate;
            row.EsteerStepMean=S.EsteerStepMean;
        end
        if isfield(S,'MseOn') && ~isnan(S.MseOn)
            row.MseOn=S.MseOn; row.MseMode=S.MseMode; row.MseCand=S.MseCand; row.MseEval=S.MseEval;
            row.MseEvalRate=S.MseEvalRate; row.MseDispMean=S.MseDispMean; row.MseClipRate=S.MseClipRate;
            row.MseClipFracMean=S.MseClipFracMean; row.MseSurvMean=S.MseSurvMean; row.MseDispIntMean=S.MseDispIntMean;
        end
        if isfield(S,'IdcCredTotal') && ~isnan(S.IdcCredTotal)
            row.IdcStableID=S.IdcStableID; row.IdcResetOnRefresh=S.IdcResetOnRefresh; row.IdcAudit=S.IdcAudit;
            row.IdcCredTotal=S.IdcCredTotal; row.IdcWrong=S.IdcWrong; row.IdcWrongRate=S.IdcWrongRate;
            row.IdcStale=S.IdcStale; row.IdcStaleRate=S.IdcStaleRate; row.IdcDropped=S.IdcDropped;
            row.IdcRefresh=S.IdcRefresh; row.IdcLeakEvents=S.IdcLeakEvents; row.IdcLeakRate=S.IdcLeakRate;
            row.IdcLeakMass=S.IdcLeakMass; row.IdcLeakMassRatio=S.IdcLeakMassRatio;
        end
        if isfield(S,'DiagEval') && ~isnan(S.DiagLifeN)
            row.DiagEval=S.DiagEval; row.DiagGB=S.DiagGB; row.DiagArc=S.DiagArc; row.DiagPop=S.DiagPop;
            row.DiagLifeEval=S.DiagLifeEval; row.DiagLifeN=S.DiagLifeN; row.DiagZeroEval=S.DiagZeroEval;
            row.DiagEvalSum=S.DiagEvalSum; row.DiagQual=S.DiagQual;
        end
        if isfield(S,'EShellShare') && ~isnan(S.EShellShare)
            row.EShellShare=S.EShellShare; row.EShellPer=S.EShellPer;
        end
        if isfield(S,'MisIslands') && ~isnan(S.MisIslands)
            row.MisIslands=S.MisIslands; row.MisMigrateOn=S.MisMigrateOn; row.MisMigrateEvery=S.MisMigrateEvery;
            row.MisMigrations=S.MisMigrations; row.MisIslandBest=S.MisIslandBest;
        end
        if isfield(S,'ExtReplace') && ~isempty(S.ExtReplace)
            row.ExtReplace=S.ExtReplace; row.ExtRepN=S.ExtRepN; row.ExtRepDistMean=S.ExtRepDistMean;
        end
        if isfield(S,'EvalOrder') && ~isempty(S.EvalOrder)
            row.FillerSteer=S.FillerSteer; row.FillerSteerN=S.FillerSteerN;
            row.FillerSteerApplied=S.FillerSteerApplied; row.EvalOrder=S.EvalOrder;
        end
        if isfield(S,'InitMode') && ~isempty(S.InitMode)
            row.InitMode=S.InitMode; row.CentreCoverage=S.CentreCoverage;
        end
        if isfield(S,'NullOffset') && ~isnan(S.NullOffset)
            row.NullOffset=S.NullOffset;
        end
        if isfield(S,'PairMode') && ~isempty(S.PairMode)
            row.PairMode=S.PairMode; row.PairN=S.PairN; row.PairEvalC=S.PairEvalC; row.PairGBC=S.PairGBC;
            row.PairArcC=S.PairArcC; row.PairGBRate=S.PairGBRate; row.PairArcRate=S.PairArcRate;
        end
        if isfield(S,'DSepRef') && ~isempty(S.DSepRef)
            row.DSepRef=S.DSepRef; row.DSepBirth=S.DSepBirth; row.DSepSpanMean=S.DSepSpanMean; row.DSepSpanLast=S.DSepSpanLast;
        end
        if isfield(S,'GaasMode') && ~isempty(S.GaasMode)
            row.GaasMode=S.GaasMode; row.GaasShellN=S.GaasShellN; row.GaasLineN=S.GaasLineN;
            row.GaasSimplexN=S.GaasSimplexN; row.GaasEval=S.GaasEval; row.GaasGB=S.GaasGB; row.GaasArc=S.GaasArc;
        end
        if isfield(S,'ShaMode') && ~isempty(S.ShaMode)
            row.ShaMode=S.ShaMode; row.ShaEvals=S.ShaEvals; row.ShaSuccess=S.ShaSuccess;
            row.ShaFactorMean=S.ShaFactorMean; row.ShaFactorMin=S.ShaFactorMin; row.ShaFactorMax=S.ShaFactorMax;
            row.ShaAUpPct=S.ShaAUpPct; row.ShaADownPct=S.ShaADownPct;
        end
        if isfield(S,'RseMode') && ~isempty(S.RseMode)
            row.RseMode=S.RseMode; row.RseEval=S.RseEval; row.RseGB=S.RseGB; row.RseArc=S.RseArc;
        end
        if isfield(S,'MixMode') && ~isempty(S.MixMode)
            row.MixMode=S.MixMode; row.MixOnGens=S.MixOnGens; row.MixAppliedGens=S.MixAppliedGens;
            row.MixAppliedRate=S.MixAppliedRate; row.MixDistMean=S.MixDistMean;
        end
        if isfield(S,'DeMode') && ~isempty(S.DeMode)
            row.DeMode=S.DeMode; row.DeStartFE=S.DeStartFE; row.DeAppliedGens=S.DeAppliedGens;
            row.DeAppliedCandidates=S.DeAppliedCandidates;
        end
        if isfield(S,'CdeMode') && ~isempty(S.CdeMode)
            row.CdeMode=S.CdeMode; row.CdeApplied=S.CdeApplied;
        end
        if isfield(S,'DrgMode') && ~isempty(S.DrgMode)
            row.DrgMode=S.DrgMode; row.DrgExploreN=S.DrgExploreN; row.DrgApplied=S.DrgApplied;
        end
        if isfield(S,'CssMode') && ~isempty(S.CssMode)
            row.CssMode=S.CssMode; row.CssN=S.CssN; row.CssDims=S.CssDims; row.CssPhaseFrac=S.CssPhaseFrac; row.CssSelect=S.CssSelect; row.CssApplied=S.CssApplied;
        end
        if isfield(S,'RedOn') && ~isnan(S.RedOn)
            row.RedOn=S.RedOn; row.RedMode=S.RedMode; row.RedEps=S.RedEps;
            row.RedDraws=S.RedDraws; row.RedRejects=S.RedRejects;
            row.RedDupN=S.RedDupN; row.RedDistN=S.RedDistN;
            row.RedDupImpRate=S.RedDupImpRate; row.RedDistImpRate=S.RedDistImpRate;
            row.RedDupArcRate=S.RedDupArcRate; row.RedDistArcRate=S.RedDistArcRate;
            row.RedSelDupRate=S.RedSelDupRate; row.RedDminMedian=S.RedDminMedian;
        end
        if isfield(S,'LltOn') && ~isnan(S.LltOn)
            row.LltOn=S.LltOn; row.LltMode=S.LltMode; row.LltRounds=S.LltRounds;
            row.LltLocalNeGlobalRate=S.LltLocalNeGlobalRate; row.LltDispMean=S.LltDispMean;
            row.LltDispMedian=S.LltDispMedian; row.LltDispP90=S.LltDispP90;
            row.LltDupSelectedRate=S.LltDupSelectedRate; row.LltG1NNMedian=S.LltG1NNMedian;
        end
        if isfield(S,'NelOn') && ~isnan(S.NelOn)
            row.NelOn=S.NelOn; row.NelMode=S.NelMode; row.NelCandidates=S.NelCandidates; row.NelSelected=S.NelSelected;
        end
        if isfield(S,'BgrOn') && ~isnan(S.BgrOn)
            row.BgrOn=S.BgrOn; row.BgrMode=S.BgrMode; row.BgrG1Cand=S.BgrG1Cand;
            row.BgrOutCand=S.BgrOutCand; row.BgrOutCandRate=S.BgrOutCandRate;
            row.BgrOutCoord=S.BgrOutCoord; row.BgrTotalCoord=S.BgrTotalCoord; row.BgrOutCoordRate=S.BgrOutCoordRate;
            row.BgrClipDistMean=S.BgrClipDistMean; row.BgrClipDistMedian=S.BgrClipDistMedian; row.BgrClipDistP90=S.BgrClipDistP90;
            row.BgrEarlyRate=S.BgrEarlyRate; row.BgrMidRate=S.BgrMidRate; row.BgrLateRate=S.BgrLateRate;
        end
        if isfield(S,'RgiOn') && ~isnan(S.RgiOn)
            row.RgiOn=S.RgiOn; row.RgiMode=S.RgiMode;
            row.RgiTriggers=S.RgiTriggers; row.RgiEvaluated=S.RgiEvaluated;
            row.RgiEvaluatedRate=S.RgiEvaluatedRate;
            if isfield(S,'RgiRestarts'), row.RgiRestarts=S.RgiRestarts; end
            if isfield(S,'RgiEvaluatedRestarts'), row.RgiEvaluatedRestarts=S.RgiEvaluatedRestarts; end
            if isfield(S,'RgiRestartRate'), row.RgiRestartRate=S.RgiRestartRate; end
        end
        if isfield(S,'WlrOn') && ~isnan(S.WlrOn)
            row.WlrOn=S.WlrOn; row.WlrMode=S.WlrMode; row.WlrMacroGens=S.WlrMacroGens;
            row.WlrLeaderChanges=S.WlrLeaderChanges; row.WlrGenWithChange=S.WlrGenWithChange;
            row.WlrChangeRate=S.WlrChangeRate; row.WlrEvaluatedG1=S.WlrEvaluatedG1;
            row.WlrStaleCount=S.WlrStaleCount; row.WlrStaleRate=S.WlrStaleRate;
            row.WlrMeanStaleDist=S.WlrMeanStaleDist; row.WlrMedianStaleDist=S.WlrMedianStaleDist;
            row.WlrP90StaleDist=S.WlrP90StaleDist;
        end
        if isfield(S,'TsdrOn') && ~isnan(S.TsdrOn)
            row.TsdrOn=S.TsdrOn; row.TsdrMode=S.TsdrMode; row.TsdrG1Eval=S.TsdrG1Eval;
            if isfield(S,'TsdrRecoveries'), row.TsdrRecoveries=S.TsdrRecoveries; end
            row.TsdrTriggers=S.TsdrTriggers; row.TsdrTriggerRate=S.TsdrTriggerRate;
            row.TsdrEarly=S.TsdrEarly; row.TsdrMid=S.TsdrMid; row.TsdrLate=S.TsdrLate;
            row.TsdrArcEvents=S.TsdrArcEvents; row.TsdrArcDistMean=S.TsdrArcDistMean;
            row.TsdrArcCoveredRate=S.TsdrArcCoveredRate; row.TsdrRecDistMean=S.TsdrRecDistMean;
            row.TsdrRecArcMean=S.TsdrRecArcMean; row.TsdrRecCoveredRate=S.TsdrRecCoveredRate;
        end
        if isfield(S,'TsdOn') && ~isnan(S.TsdOn)
            row.TsdOn=S.TsdOn; row.TsdMode=S.TsdMode; row.TsdG1Eval=S.TsdG1Eval;
            row.TsdG1Split=S.TsdG1Split; row.TsdStateSplitRate=S.TsdStateSplitRate;
            row.TsdEEval=S.TsdEEval; row.TsdECursorOnly=S.TsdECursorOnly; row.TsdCursorOnlyRate=S.TsdCursorOnlyRate;
            row.TsdOEEval=S.TsdOEEval; row.TsdOECursorOnly=S.TsdOECursorOnly; row.TsdOECursorOnlyRate=S.TsdOECursorOnlyRate;
            row.TsdProtectUpdates=S.TsdProtectUpdates; row.TsdMeanGapDist=S.TsdMeanGapDist;
            row.TsdMeanGapFit=S.TsdMeanGapFit; row.TsdMaxGapDist=S.TsdMaxGapDist;
        end
        if isfield(S,'CaglOn') && ~isnan(S.CaglOn)
            row.CaglOn=S.CaglOn; row.CaglMode=S.CaglMode; row.CaglRounds=S.CaglRounds;
            row.CaglCollapseRounds=S.CaglCollapseRounds; row.CaglCollapseRate=S.CaglCollapseRate;
            row.CaglEligibleRounds=S.CaglEligibleRounds; row.CaglEligibleShare=S.CaglEligibleShare;
            row.CaglEligibleCentersMean=S.CaglEligibleCentersMean; row.CaglGuidedCandidates=S.CaglGuidedCandidates;
            row.CaglDirectionEvents=S.CaglDirectionEvents; row.CaglMeanNormDiff=S.CaglMeanNormDiff;
            row.CaglMeanCos=S.CaglMeanCos; row.CaglDirChanged10=S.CaglDirChanged10;
            row.CaglRandomSelections=S.CaglRandomSelections;
        end
        if isfield(S,'NparOn') && ~isnan(S.NparOn)
            row.NparOn=S.NparOn; row.NparMode=S.NparMode; row.NparFullBetter=S.NparFullBetter;
            row.NparFarEvents=S.NparFarEvents; row.NparChangedTarget=S.NparChangedTarget;
            row.NparEligibleEvents=S.NparEligibleEvents; row.NparFallbackEvents=S.NparFallbackEvents;
            row.NparActualReplacements=S.NparActualReplacements; row.NparRandomDifferent=S.NparRandomDifferent;
            row.NparNNEvents=S.NparNNEvents; row.NparMeanNNBefore=S.NparMeanNNBefore;
            row.NparMeanNNGlobal=S.NparMeanNNGlobal; row.NparMeanNNPair=S.NparMeanNNPair;
        end
        if isfield(S,'VGAOn') && ~isnan(S.VGAOn)
            row.VGAOn=S.VGAOn; row.VGAMode=S.VGAMode; row.VGAEvalCount=S.VGAEvalCount;
            row.VGASuccCount=S.VGASuccCount; row.VGAAcceptCount=S.VGAAcceptCount;
            row.VGAAcceptRate=S.VGAAcceptRate; row.VGASuccessRate=S.VGASuccessRate;
            row.VGAPReplaceMean=S.VGAPReplaceMean;
        end
        row.ImpCnt1=ic(1); row.ImpCnt2=ic(2); row.ImpCnt3=ic(3); row.ImpCnt4=ic(4);
            row.ImpMag1=im(1); row.ImpMag2=im(2); row.ImpMag3=im(3); row.ImpMag4=im(4);
        end
        row.K=S.K;
        if isfield(S,'ECPSOn') && ~isnan(S.ECPSOn)
            row.ECPSOn=S.ECPSOn; row.ECPSMode=S.ECPSMode; row.ECPSWindow=S.ECPSWindow;
            ec=double(S.ECPSActionCounts); et=max(sum(ec),1);
            row.ECPSAction1Pct=ec(1)/et; row.ECPSAction2Pct=ec(2)/et;
            row.ECPSAction3Pct=ec(3)/et; row.ECPSActionAvgPct=ec(4)/et;
            row.ECPSEvalCount=sum(S.ECPSEvalCounts); row.ECPSSuccCount=sum(S.ECPSSuccCounts);
            ae=double(S.ECPSEvalCounts); as=double(S.ECPSSuccCounts);
            gb=double(S.ECPSGBSuccCounts); arc=double(S.ECPSArcSuccCounts); mag=double(S.ECPSMagSum);
            row.ECPSGBSucc=sum(gb); row.ECPSArcSucc=sum(arc); row.ECPSMagSum=sum(mag);
            row.ECPSAction1Eval=ae(1); row.ECPSAction2Eval=ae(2); row.ECPSAction3Eval=ae(3); row.ECPSActionAvgEval=ae(4);
            row.ECPSAction1Succ=as(1); row.ECPSAction2Succ=as(2); row.ECPSAction3Succ=as(3); row.ECPSActionAvgSucc=as(4);
            row.ECPSSuccessRate=row.ECPSSuccCount/max(row.ECPSEvalCount,1);
            row.ECPSProb1Mean=S.ECPSProbMean(1); row.ECPSProb2Mean=S.ECPSProbMean(2);
            row.ECPSProb3Mean=S.ECPSProbMean(3); row.ECPSProbAvgMean=S.ECPSProbMean(4);
            row.ECPSEntropyMean=S.ECPSEntropyMean;
        end
        row.QuotaAct1Pct=S.QuotaAct1Pct; row.QuotaAct2Pct=S.QuotaAct2Pct; row.QuotaAct3Pct=S.QuotaAct3Pct;
        row.RewardMean=S.RewardMean; row.GBWindowPct=S.GBWindowPct;
        if ~isnan(S.QActionCounts(1))
            row.QAct1=S.QActionCounts(1); row.QAct2=S.QActionCounts(2); row.QAct3=S.QActionCounts(3);
            sv=S.QStateVisits;
            row.QState1=sv(1); row.QState2=sv(2); row.QState3=sv(3);
            row.QState4=sv(4); row.QState5=sv(5); row.QState6=sv(6);
        end
        row.NImprove=M.NImprove; row.ImprovingFERate=M.ImprovingFERate;
        row.NStagEpisodes=M.NStagEpisodes;
        row.NRecoveredWindow=M.NRecoveredWindow; row.NRecoveredEventual=M.NRecoveredEventual;
        row.RecoveryProbWindow=M.RecoveryProbWindow;
        row.RecoveryEventualProb=M.RecoveryEventualProb;
        row.RecoveryMedExtraFE=M.RecoveryMedExtraFE;
        row.LongStagShare=M.LongStagShare; row.FinalStagLen=M.FinalStagLen;
        q=M.ImproveRateQ;
        row.ImprovRateQ1=q(1); row.ImprovRateQ2=q(2); row.ImprovRateQ3=q(3); row.ImprovRateQ4=q(4);
        ct=M.CheckT;
        row.CheckT10=ct(1); row.CheckT20=ct(2); row.CheckT50=ct(3); row.CheckT80=ct(4); row.CheckT100=ct(5);
        row.NovMean=NV.Mean; row.NovMedian=NV.Median; row.NSamples=NV.NSamples;
        row.NovRate=NV.NovelRate; row.NovelUsefulRate=NV.UsefulNovelRate;
        row.NovelStrictImprove=NV.StrictNovelImprove;
        nq=NV.NovRateQ;
        row.NovRateQ1=nq(1); row.NovRateQ2=nq(2); row.NovRateQ3=nq(3); row.NovRateQ4=nq(4);
    else
        row.Status="failed";
        row.Message=string(r.error);
    end
    rows{i}=row;
end
Tbl=struct2table(vertcat(rows{:}));
writetable(Tbl,fullfile(outDir,'runs.csv'));
nOk=sum(Tbl.Status=="ok"); nBad=sum(Tbl.Status=="failed");
fprintf('[collect_sq] %s: %d ok / %d failed / %d total\n',outDir,nOk,nBad,n);
end

function row=emptyRow()
row=struct('RunID',NaN,'Algorithm',"",'Family',"",'FunctionID',NaN,'D',NaN,'Seed',NaN, ...
    'Status',"",'Message',"",'BestCost',NaN,'FinalError',NaN, ...
    'Evaluations',NaN,'ProbeFE',NaN,'Rounds',NaN,'Seconds',NaN, ...
    'NCandidateGenerated',NaN,'NDistanceOps',NaN,'NArchiveInserts',NaN,'ArchiveSize',NaN,'K',NaN, ...
    'ImpCnt1',NaN,'ImpCnt2',NaN,'ImpCnt3',NaN,'ImpCnt4',NaN, ...
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
    'TsdrOn',NaN,'TsdrMode',"",'TsdrG1Eval',NaN,'TsdrTriggers',NaN,'TsdrTriggerRate',NaN,'TsdrRecoveries',NaN, ...
    'TsdrEarly',NaN,'TsdrMid',NaN,'TsdrLate',NaN,'TsdrArcEvents',NaN,'TsdrArcDistMean',NaN, ...
    'TsdrArcCoveredRate',NaN,'TsdrRecDistMean',NaN,'TsdrRecArcMean',NaN,'TsdrRecCoveredRate',NaN, ...
    'WlrOn',NaN,'WlrMode',"",'WlrMacroGens',NaN,'WlrLeaderChanges',NaN,'WlrGenWithChange',NaN, ...
    'WlrChangeRate',NaN,'WlrEvaluatedG1',NaN,'WlrStaleCount',NaN,'WlrStaleRate',NaN, ...
    'WlrMeanStaleDist',NaN,'WlrMedianStaleDist',NaN,'WlrP90StaleDist',NaN, ...
    'RgiOn',NaN,'RgiMode',"",'RgiTriggers',NaN,'RgiEvaluated',NaN,'RgiEvaluatedRate',NaN, ...
    'BgrOn',NaN,'BgrMode',"",'BgrG1Cand',NaN,'BgrOutCand',NaN,'BgrOutCandRate',NaN, ...
    'BgrOutCoord',NaN,'BgrTotalCoord',NaN,'BgrOutCoordRate',NaN,'BgrClipDistMean',NaN, ...
    'BgrClipDistMedian',NaN,'BgrClipDistP90',NaN,'BgrEarlyRate',NaN,'BgrMidRate',NaN,'BgrLateRate',NaN, ...
    'NelOn',NaN,'NelMode',"",'NelCandidates',NaN,'NelSelected',NaN, ...
    'RefOn',NaN,'RefMode',"",'RefCandidates',NaN,'RefSelected',NaN, ...
    'PcssOn',NaN,'PcssMode',"",'PcssN',NaN,'PcssGuideEval',NaN,'PcssGuideBetter',NaN,'PcssGuideRate',NaN, ...
    'LltOn',NaN,'LltMode',"",'LltRounds',NaN,'LltLocalNeGlobalRate',NaN,'LltDispMean',NaN, ...
    'RedOn',NaN,'RedMode',"",'RedEps',NaN,'RedDraws',NaN,'RedRejects',NaN,'RedDupN',NaN,'RedDistN',NaN, ...
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
    'EsteerOn',NaN,'EsteerMode',"",'EsteerGen',NaN,'EsteerTrig',NaN, ...
    'EsteerTrigRate',NaN,'EsteerStepMean',NaN, ...
    'MseOn',NaN,'MseMode',"",'MseCand',NaN,'MseEval',NaN,'MseEvalRate',NaN,'MseDispMean',NaN,'MseClipRate',NaN, ...
    'MseClipFracMean',NaN,'MseSurvMean',NaN,'MseDispIntMean',NaN, ...
    'IdcStableID',NaN,'IdcResetOnRefresh',NaN,'IdcAudit',NaN,'IdcCredTotal',NaN,'IdcWrong',NaN,'IdcWrongRate',NaN,'IdcStale',NaN,'IdcStaleRate',NaN,'IdcDropped',NaN,'IdcRefresh',NaN,'IdcLeakEvents',NaN,'IdcLeakRate',NaN,'IdcLeakMass',NaN,'IdcLeakMassRatio',NaN, ...
    'DiagEval',NaN,'DiagGB',NaN,'DiagArc',NaN,'DiagPop',NaN, ...
    'DiagLifeEval',NaN,'DiagLifeN',NaN,'DiagZeroEval',NaN,'DiagEvalSum',NaN,'DiagQual',NaN, ...
    'EShellShare',NaN,'EShellPer',NaN, ...
    'MisIslands',NaN,'MisMigrateOn',NaN,'MisMigrateEvery',NaN,'MisMigrations',NaN,'MisIslandBest',NaN, ...
    'ExtReplace',"",'ExtRepN',NaN,'ExtRepDistMean',NaN, ...
    'FillerSteer',NaN,'FillerSteerN',NaN,'FillerSteerApplied',NaN,'EvalOrder',"", ...
    'InitMode',"",'CentreCoverage',NaN, ...
    'NullOffset',NaN, ...
    'PairMode',"",'PairN',NaN,'PairEvalC',NaN,'PairGBC',NaN,'PairArcC',NaN,'PairGBRate',NaN,'PairArcRate',NaN, ...
    'DSepRef',"",'DSepBirth',NaN,'DSepSpanMean',NaN,'DSepSpanLast',NaN, ...
    'GaasMode',"",'GaasShellN',NaN,'GaasLineN',NaN,'GaasSimplexN',NaN,'GaasEval',NaN,'GaasGB',NaN,'GaasArc',NaN, ...
    'ShaMode',"",'ShaEvals',NaN,'ShaSuccess',NaN,'ShaTrace',[],'ShaFactorMean',NaN,'ShaFactorMin',NaN,'ShaFactorMax',NaN,'ShaAUpPct',NaN,'ShaADownPct',NaN, ...
    'RseMode',"",'RseEval',NaN,'RseGB',NaN,'RseArc',NaN, ...
    'MixMode',"",'MixOnGens',NaN,'MixAppliedGens',NaN,'MixAppliedRate',NaN,'MixDistMean',NaN, ...
    'DeMode',"",'DeStartFE',NaN,'DeAppliedGens',NaN,'DeAppliedCandidates',NaN, ...
    'CdeMode',"",'CdeApplied',NaN, ...
    'DrgMode',"",'DrgExploreN',NaN,'DrgApplied',NaN, ...
    'CssMode',"",'CssN',NaN,'CssDims',NaN,'CssPhaseFrac',NaN,'CssSelect',"",'CssApplied',NaN, ...
    'RedDupImpRate',NaN,'RedDistImpRate',NaN,'RedDupArcRate',NaN,'RedDistArcRate',NaN, ...
    'RedSelDupRate',NaN,'RedDminMedian',NaN, ...
    'LltDispMedian',NaN,'LltDispP90',NaN,'LltDupSelectedRate',NaN,'LltG1NNMedian',NaN, ...
    'PcssRandEval',NaN,'PcssRandBetter',NaN,'PcssRandRate',NaN,'PcssFallbackGens',NaN,'PcssGuidedGens',NaN, ...
    'RgiRestarts',NaN,'RgiEvaluatedRestarts',NaN,'RgiRestartRate',NaN, ...
    'ImpMag1',NaN,'ImpMag2',NaN,'ImpMag3',NaN,'ImpMag4',NaN, ...
    'QuotaAct1Pct',NaN,'QuotaAct2Pct',NaN,'QuotaAct3Pct',NaN,'RewardMean',NaN,'GBWindowPct',NaN, ...
    'ECPSOn',NaN,'ECPSMode',"",'ECPSWindow',NaN, ...
    'ECPSAction1Pct',NaN,'ECPSAction2Pct',NaN,'ECPSAction3Pct',NaN,'ECPSActionAvgPct',NaN, ...
    'ECPSEvalCount',NaN,'ECPSSuccCount',NaN,'ECPSSuccessRate',NaN, ...
    'ECPSAction1Eval',NaN,'ECPSAction2Eval',NaN,'ECPSAction3Eval',NaN,'ECPSActionAvgEval',NaN, ...
    'ECPSAction1Succ',NaN,'ECPSAction2Succ',NaN,'ECPSAction3Succ',NaN,'ECPSActionAvgSucc',NaN, ...
    'ECPSGBSucc',NaN,'ECPSArcSucc',NaN,'ECPSMagSum',NaN, ...
    'ECPSProb1Mean',NaN,'ECPSProb2Mean',NaN,'ECPSProb3Mean',NaN,'ECPSProbAvgMean',NaN, ...
    'ECPSEntropyMean',NaN, ...
    'QAct1',NaN,'QAct2',NaN,'QAct3',NaN, ...
    'QState1',NaN,'QState2',NaN,'QState3',NaN,'QState4',NaN,'QState5',NaN,'QState6',NaN, ...
    'NImprove',NaN,'ImprovingFERate',NaN,'NStagEpisodes',NaN, ...
    'NRecoveredWindow',NaN,'NRecoveredEventual',NaN, ...
    'RecoveryProbWindow',NaN,'RecoveryEventualProb',NaN,'RecoveryMedExtraFE',NaN, ...
    'LongStagShare',NaN,'FinalStagLen',NaN, ...
    'ImprovRateQ1',NaN,'ImprovRateQ2',NaN,'ImprovRateQ3',NaN,'ImprovRateQ4',NaN, ...
    'CheckT10',NaN,'CheckT20',NaN,'CheckT50',NaN,'CheckT80',NaN,'CheckT100',NaN, ...
    'NovMean',NaN,'NovMedian',NaN,'NSamples',NaN,'NovRate',NaN, ...
    'NovelUsefulRate',NaN,'NovelStrictImprove',NaN, ...
    'NovRateQ1',NaN,'NovRateQ2',NaN,'NovRateQ3',NaN,'NovRateQ4',NaN);
end
