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
