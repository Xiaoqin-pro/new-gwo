function Tbl=collect_results(outDir)
%COLLECT_RESULTS  Flatten one batch directory into runs.csv (+ one-line summary).
%   Reads runs/run_*.mat records (written by overnight.runBatch4), flattens the
%   per-run metrics into a table, and writes runs.csv in the batch directory.
%   Failed runs are kept with Status='failed' and their error message.
files=dir(fullfile(outDir,'runs','run_*.mat'));
assert(~isempty(files),'collect_results:empty','No run_*.mat in %s',outDir);
n=numel(files);
rows=cell(n,1);
for i=1:n
    a=load(fullfile(files(i).folder,files(i).name),'record');
    r=a.record;
    row=emptyRow();
    row.RunID=r.id;
    if strcmp(r.status,'ok')
        res=r.result; M=res.Metrics; NV=res.Novelty;
        row.Algorithm=string(res.Algorithm);
        if isfield(res,'Family'), row.Family=string(res.Family); else, row.Family=string(res.Algorithm); end
        row.FunctionID=res.FunctionID; row.D=res.D; row.Seed=res.Seed;
        row.Status="ok";
        row.BestCost=res.BestCost;
        row.FinalError=res.BestCost-100*res.FunctionID;
        row.Evaluations=res.Evaluations; row.ProbeFE=res.ProbeFE;
        row.Rounds=res.Rounds; row.Seconds=res.Seconds;
        row.NCandidateGenerated=res.NCandidateGenerated;
        row.NDistanceOps=res.NDistanceOps;
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
nOk=sum(Tbl.Status=="ok");
nBad=sum(Tbl.Status=="failed");
fprintf('[collect_results] %s: %d ok / %d failed / %d total\n',outDir,nOk,nBad,n);
end

function row=emptyRow()
row=struct('RunID',NaN,'Algorithm',"",'Family',"",'FunctionID',NaN,'D',NaN,'Seed',NaN, ...
    'Status',"",'Message',"",'BestCost',NaN,'FinalError',NaN, ...
    'Evaluations',NaN,'ProbeFE',NaN,'Rounds',NaN,'Seconds',NaN, ...
    'NCandidateGenerated',NaN,'NDistanceOps',NaN, ...
    'NImprove',NaN,'ImprovingFERate',NaN,'NStagEpisodes',NaN,'NRecoveredWindow',NaN,'NRecoveredEventual',NaN, ...
    'RecoveryProbWindow',NaN,'RecoveryEventualProb',NaN,'RecoveryMedExtraFE',NaN, ...
    'LongStagShare',NaN,'FinalStagLen',NaN, ...
    'ImprovRateQ1',NaN,'ImprovRateQ2',NaN,'ImprovRateQ3',NaN,'ImprovRateQ4',NaN, ...
    'CheckT10',NaN,'CheckT20',NaN,'CheckT50',NaN,'CheckT80',NaN,'CheckT100',NaN, ...
    'NovMean',NaN,'NovMedian',NaN,'NSamples',NaN,'NovRate',NaN, ...
    'NovelUsefulRate',NaN,'NovelStrictImprove',NaN, ...
    'NovRateQ1',NaN,'NovRateQ2',NaN,'NovRateQ3',NaN,'NovRateQ4',NaN);
end




