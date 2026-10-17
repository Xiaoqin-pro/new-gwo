function m=trace_metrics(T,budget,W)
%TRACE_METRICS  停滞 / 恢复 / 有效性指标（预注册定义，全部来自 T 曲线）。
%   T      : budget-by-1，T(fe) = 第 fe 次真实评价后的 global best。
%   budget : 真实 FE 预算。
%   W      : 停滞窗口（FE），本工程预注册为 max(50, 1% budget)。
%
%   定义（写在 experiments/registry.csv 与 docs 里，先于正式实验）：
%     ImprovingFERate     : 严格刷新 global best 的评价数 / budget。
%     无改善段 (episode)  : 相邻两次 global-best 改善之间的评价段，以及
%                           最后一次改善之后的尾段。
%     NStagEpisodes       : 长度 >= W 的无改善段个数（首段除外）。
%     RecoveryProbWindow  : 触达 W 后，在额外 R=4W 次真实评价内出现改善的
%                           停滞段比例（"窗口内恢复"）。
%     RecoveryEventualProb: 停滞段最终以改善结束（非尾段）的比例。
%     RecoveryMedExtraFE  : 恢复所需额外评价（段长 - W）的中位数。
%     LongStagShare       : 长度 >= W 的无改善段总 FE 占预算比例。
%     ImprovRateQ         : 四个 1/4 预算区间的改善事件率。
%     CheckT              : 10/20/50/80/100% 预算检查点的 best-so-far。
T=T(:);
assert(numel(T)==budget);
impr=find(T(2:end)<T(1:end-1))+1;
m.NImprove=numel(impr);
m.ImprovingFERate=numel(impr)/budget;
edges=[0; impr(:); budget+1];
len=diff(edges)-1;
segLen=len(2:end);                       % 首段（尚无先前改善）不计
nSeg=numel(segLen);
isLast=false(nSeg,1); if nSeg>0, isLast(end)=true; end
stag=segLen>=W;
m.NStagEpisodes=sum(stag);
m.NRecoveredWindow=NaN; m.NRecoveredEventual=NaN;
if m.NStagEpisodes==0
    m.RecoveryProbWindow=NaN; m.RecoveryEventualProb=NaN; m.RecoveryMedExtraFE=NaN;
else
    R=4*W;
    recov=stag & ~isLast & (segLen<=W+R);
    m.NRecoveredWindow=sum(recov); m.NRecoveredEventual=sum(stag & ~isLast);
    m.RecoveryProbWindow=sum(recov)/sum(stag);
    m.RecoveryEventualProb=sum(stag & ~isLast)/sum(stag);
    extra=segLen(stag & ~isLast)-W;
    if isempty(extra), m.RecoveryMedExtraFE=NaN; else, m.RecoveryMedExtraFE=median(extra); end
end
m.LongStagShare=sum(segLen(stag))/budget;
if nSeg>0, m.FinalStagLen=segLen(end); else, m.FinalStagLen=budget; end
q=floor(linspace(1,budget+1,5));
m.ImproveRateQ=zeros(1,4);
for k=1:4
    m.ImproveRateQ(k)=sum(impr>=q(k)&impr<q(k+1))/(q(k+1)-q(k));
end
cp=[0.1 0.2 0.5 0.8 1.0];
idxs=max(1,round(cp*budget));
m.CheckFE=idxs;
m.CheckT=T(idxs)';
end

