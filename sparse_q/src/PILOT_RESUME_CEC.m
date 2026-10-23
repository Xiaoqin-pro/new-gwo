function [Best,T,info]=PILOT_RESUME_CEC(f,state,~,N,seed)
%PILOT_RESUME_CEC  Scale-normalized pilot racing with state continuation.
%   Both cores run the same pilot budget.  The selected core continues from
%   its verified checkpoint; no point is reevaluated and total FE is exact.
if ~isfield(state,'pilotFrac') || isempty(state.pilotFrac), state.pilotFrac=0.20; end
pilotRule='scale2'; if isfield(state,'pilotRule') && ~isempty(state.pilotRule), pilotRule=lower(char(state.pilotRule)); end
fid=0; if isfield(state,'functionID') && ~isempty(state.functionID), fid=state.functionID; end
budget=state.maxEvaluations; Bp=max(N,round(state.pilotFrac*budget)); Brem=budget-2*Bp;
assert(Brem>=N);
s=state; s.maxEvaluations=Bp;
[Bc,Tc,ic]=CMAES_CEC(f,s,[],N,seed+111111);
[Bl,Tl,il]=LSHADE_CEC(f,s,[],N,seed+777777);
initCost=Tc(min(N,numel(Tc))); cErr=max(0,Bc.Cost-100*fid); lErr=max(0,Bl.Cost-100*fid); initErr=max(1,initCost-100*fid);
cRel=cErr/initErr; lRel=lErr/initErr;
if strcmp(pilotRule,'scale2')
    chooseLS=(lErr<cErr) && (lRel>5e-9) && (cRel>1e-7) && (cRel<1e-3);
else
    chooseLS=Bl.Cost<Bc.Cost;
end
if chooseLS
    winner='LSHADE'; pilotBest=Bl;
    s2=state; s2.maxEvaluations=Brem; s2.initialPopulation=il.FinalPopulation; s2.initialFitness=il.FinalFitness;
    s2.initialBest=il.FinalBest; s2.initialArchive=il.FinalArchive;
    s2.initialMemoryF=il.FinalMemoryF; s2.initialMemoryCR=il.FinalMemoryCR; s2.initialMemoryPos=il.FinalMemoryPos;
    s2.resumeStartFE=Bp; s2.resumeTotalBudget=budget; s2.resumeInitialSize=N;
    [Bf,Tf,iff]=LSHADE_RESUME(f,s2,[],il.FinalPopulationSize,seed+333333);
else
    winner='CMAES'; pilotBest=Bc;
    s2=state; s2.maxEvaluations=Brem; s2.cmaState=ic.FinalCMAState;
    [Bf,Tf,iff]=CMAES_RESUME(f,s2,[],N,seed+333333);
end
if pilotBest.Cost<Bf.Cost, Best=pilotBest; else, Best=Bf; end
T=[min(Tc(:),Best.Cost);min(Tl(:),Best.Cost);min(Tf(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info.Algorithm='PILOT-RESUME'; info.Evaluations=budget; info.Rounds=ic.Rounds+il.Rounds+iff.Rounds;
info.PilotFE=Bp; info.FinalFE=Brem; info.CMAESPilot=Bc.Cost; info.LSHADEPilot=Bl.Cost;
info.Winner=winner; info.FinalCoreCost=Bf.Cost; info.PilotBest=pilotBest.Cost;
info.PilotRule=pilotRule; info.PilotInitialBest=initCost; info.PilotCMARel=cRel; info.PilotLSRel=lRel;
info.CMAESInfo=ic; info.LSHADEInfo=il; info.FinalInfo=iff;
end
