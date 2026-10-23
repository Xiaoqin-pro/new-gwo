function [Best,T,info]=IPOP_CMA_CEC(f,state,~,N,seed)
%IPOP_CMA_CEC  CMA with a stagnation-triggered population increase restart from current best.
budget=state.maxEvaluations; block=max(2*N,round(0.20*budget)); tol=5e-4; patience=1;
if isfield(state,'ipopPatience') && ~isempty(state.ipopPatience), patience=state.ipopPatience; end
if isfield(state,'ipopTol') && ~isempty(state.ipopTol), tol=state.ipopTol; end
used=0; Tparts=cell(0,1); bestStart=inf; stagn=0; restarted=false; restartFE=NaN; lambdaNow=N;
s=state; s.maxEvaluations=min(block,budget); [Best,Tb,ib]=CMAES_CEC(f,s,[],N,seed+111111);
Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; bestStart=Best.Cost;
while used<budget
    rem=budget-used; b=min(block,rem); if b<N, break; end
    if ~restarted
        s=state; s.maxEvaluations=b; s.cmaState=cmaState; [B,Tb,ib]=CMAES_RESUME(f,s,[],lambdaNow,seed+111111+used);
    else
        X=makeRestartAroundBest(Best.Vector,N,state.lowerBound,state.upperBound);
        s=state; s.maxEvaluations=b; s.initialPopulation=X; s.cmaLambda=100;
        [B,Tb,ib]=CMAES_CEC(f,s,[],lambdaNow,seed+333333+used);
    end
    Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState;
    if B.Cost<Best.Cost, Best=B; end
    rel=(bestStart-Best.Cost)/max(abs(bestStart),1); if rel<tol, stagn=stagn+1; else, stagn=0; end
    bestStart=Best.Cost;
    if stagn>=patience && ~restarted
        restarted=true; lambdaNow=100; restartFE=used;
    end
end
T=zeros(0,1); for k=1:numel(Tparts), T=[T;Tparts{k}(:)]; end %#ok<AGROW>
T=min(T,Best.Cost); T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='IPOP-CMA'; info.Evaluations=budget; info.Rounds=used; info.Restarted=double(restarted);
info.RestartFE=restartFE; info.FinalLambda=lambdaNow; info.BlockFE=block; info.Tol=tol; info.FinalCMAState=cmaState;
end
function X=makeRestartAroundBest(base,N,lb,ub)
D=numel(base); nmax=max(2,round(0.5*N)); X=[base+20*randn(nmax,D);-100+200*rand(N-nmax,D)];
lo=repmat(lb,size(X,1),1); hi=repmat(ub,size(X,1),1); X=max(min(X,hi),lo);
end
