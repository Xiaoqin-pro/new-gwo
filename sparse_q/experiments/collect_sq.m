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
            row.ImpCnt1=ic(1); row.ImpCnt2=ic(2); row.ImpCnt3=ic(3); row.ImpCnt4=ic(4);
            row.ImpMag1=im(1); row.ImpMag2=im(2); row.ImpMag3=im(3); row.ImpMag4=im(4);
        end
        if isfield(S,'EvalCnt')
            ec=S.EvalCnt;
            row.EvalCnt1=ec(1); row.EvalCnt2=ec(2); row.EvalCnt3=ec(3); row.EvalCnt4=ec(4);
        end
        row.G2EvalCount=S.G2EvalCount; row.G2AlphaImp=S.G2AlphaImp;
        row.G2PopImp=S.G2PopImp; row.G2NoImp=S.G2NoImp; row.G2GlobalImp=S.G2GlobalImp;
        row.G2RadiusStart=S.G2RadiusStart; row.G2RadiusEnd=S.G2RadiusEnd;
        row.G2RadiusMean=S.G2RadiusMean; row.G2RadiusMin=S.G2RadiusMin; row.G2RadiusMax=S.G2RadiusMax;
        row.G2AFEAlways=S.G2AFEAlways; row.G2AFERandomDir=S.G2AFERandomDir;
        row.G2AFETriggerFrac=S.G2AFETriggerFrac; row.G2AFEMinArc=S.G2AFEMinArc;
        row.G2AFEMinPairFrac=S.G2AFEMinPairFrac; row.G2AFELambdaMin=S.G2AFELambdaMin;
        row.G2AFELambdaMax=S.G2AFELambdaMax; row.G2AFEEpsFrac=S.G2AFEEpsFrac;
        row.G2AFEActiveRounds=S.G2AFEActiveRounds; row.G2AFEPairValidRounds=S.G2AFEPairValidRounds;
        row.G2AFECandidates=S.G2AFECandidates; row.G2AFEFallbackCandidates=S.G2AFEFallbackCandidates;
        row.G2AFEStepMean=S.G2AFEStepMean; row.G2AFEGlobalImp=S.G2AFEGlobalImp;
        row.G2AFEArchiveImp=S.G2AFEArchiveImp; row.G2AFEAccept=S.G2AFEAccept;
        row.K=S.K;
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
    'ImpMag1',NaN,'ImpMag2',NaN,'ImpMag3',NaN,'ImpMag4',NaN, ...
    'EvalCnt1',NaN,'EvalCnt2',NaN,'EvalCnt3',NaN,'EvalCnt4',NaN, ...
    'G2EvalCount',NaN,'G2AlphaImp',NaN,'G2PopImp',NaN,'G2NoImp',NaN,'G2GlobalImp',NaN, ...
    'G2RadiusStart',NaN,'G2RadiusEnd',NaN,'G2RadiusMean',NaN,'G2RadiusMin',NaN,'G2RadiusMax',NaN, ...
    'G2AFEAlways',NaN,'G2AFERandomDir',NaN,'G2AFETriggerFrac',NaN,'G2AFEMinArc',NaN, ...
    'G2AFEMinPairFrac',NaN,'G2AFELambdaMin',NaN,'G2AFELambdaMax',NaN,'G2AFEEpsFrac',NaN, ...
    'G2AFEActiveRounds',NaN,'G2AFEPairValidRounds',NaN,'G2AFECandidates',NaN, ...
    'G2AFEFallbackCandidates',NaN,'G2AFEStepMean',NaN,'G2AFEGlobalImp',NaN, ...
    'G2AFEArchiveImp',NaN,'G2AFEAccept',NaN, ...
    'QuotaAct1Pct',NaN,'QuotaAct2Pct',NaN,'QuotaAct3Pct',NaN,'RewardMean',NaN,'GBWindowPct',NaN, ...
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
