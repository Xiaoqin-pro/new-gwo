function [Best,T,info]=ADAPT_CORE_CEC(f,state,~,N,seed)
%ADAPT_CORE_CEC  CMA-ES with stagnation-triggered L-SHADE takeover.
budget=state.maxEvaluations; block=max(2*N,round(0.10*budget));
tol=5e-4; patience=3; if isfield(state,'adaptPatience') && ~isempty(state.adaptPatience), patience=state.adaptPatience; end; used=0; Tparts=cell(0,1); bestStart=inf; stagn=0; switched=false; switchFE=NaN;
s=state; s.maxEvaluations=min(block,budget); [Best,Tb,ib]=CMAES_CEC(f,s,[],N,seed+111111);
Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState; bestStart=Best.Cost; firstCMA=Best.Cost;
while used<budget && ~switched
    rem=budget-used; b=min(block,rem); if b<N, break; end
    s=state; s.maxEvaluations=b; s.cmaState=cmaState; [B,Tb,ib]=CMAES_RESUME(f,s,[],N,seed+111111+used);
    Tparts{end+1}=Tb; used=used+ib.Evaluations; cmaState=ib.FinalCMAState;
    if B.Cost<Best.Cost, Best=B; end
    rel=(bestStart-Best.Cost)/max(abs(bestStart),1); if rel<tol, stagn=stagn+1; else, stagn=0; end
    bestStart=Best.Cost;
    if stagn>=patience
        rem=budget-used;
        if rem>=N
            s2=state; s2.maxEvaluations=rem; [Bl,Tl,il]=LSHADE_CEC(f,s2,[],N,seed+777777);
            Tparts{end+1}=Tl; used=used+il.Evaluations; switched=true; switchFE=used-il.Evaluations;
            if Bl.Cost<Best.Cost, Best=Bl; end
        end
        break;
    end
end
T=zeros(0,1); for k=1:numel(Tparts), T=[T;Tparts{k}(:)]; end %#ok<AGROW>
T=min(T,Best.Cost); T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='ADAPT-CORE'; info.Evaluations=budget; info.Rounds=used; info.Switched=double(switched); info.SwitchFE=switchFE;
info.BlockFE=block; info.StagnationTol=tol; info.FirstCMA=firstCMA; info.Patience=patience;
end
