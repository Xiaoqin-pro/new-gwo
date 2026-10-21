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
