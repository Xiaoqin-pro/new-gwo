function [Best,T,info]=PILOT_ASYM_CEC(f,state,~,N,seed)
%PILOT_ASYM_CEC  Pilot racing with asymmetric continuation.
% CMA winner continues its covariance; LSHADE winner restarts because its
% pilot population has already been reduced by the short-budget schedule.
if ~isfield(state,'pilotFrac') || isempty(state.pilotFrac), state.pilotFrac=0.20; end
fid=0; if isfield(state,'functionID') && ~isempty(state.functionID), fid=state.functionID; end
budget=state.maxEvaluations; Bp=max(N,round(state.pilotFrac*budget)); Brem=budget-2*Bp; assert(Brem>=N);
s=state; s.maxEvaluations=Bp;
[Bc,Tc,ic]=CMAES_CEC(f,s,[],N,seed+111111);
[Bl,Tl,il]=LSHADE_CEC(f,s,[],N,seed+777777);
initCost=Tc(min(N,numel(Tc))); cErr=max(0,Bc.Cost-100*fid); lErr=max(0,Bl.Cost-100*fid); initErr=max(1,initCost-100*fid);
cRel=cErr/initErr; lRel=lErr/initErr;
chooseLS=(lErr<cErr) && (lRel>5e-9) && (cRel>1e-7) && (cRel<1e-3);
if chooseLS
    winner='LSHADE'; pilotBest=Bl; s2=state; s2.maxEvaluations=Brem;
    [Bf,Tf,iff]=LSHADE_CEC(f,s2,[],N,seed+333333);
else
    winner='CMAES'; pilotBest=Bc; s2=state; s2.maxEvaluations=Brem; s2.cmaState=ic.FinalCMAState;
    [Bf,Tf,iff]=CMAES_RESUME(f,s2,[],N,seed+333333);
end
if pilotBest.Cost<Bf.Cost, Best=pilotBest; else, Best=Bf; end
T=[min(Tc(:),Best.Cost);min(Tl(:),Best.Cost);min(Tf(:),Best.Cost)]; T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info.Algorithm='PILOT-ASYM'; info.Evaluations=budget; info.Rounds=ic.Rounds+il.Rounds+iff.Rounds;
info.PilotFE=Bp; info.FinalFE=Brem; info.CMAESPilot=Bc.Cost; info.LSHADEPilot=Bl.Cost;
info.Winner=winner; info.FinalCoreCost=Bf.Cost; info.PilotBest=pilotBest.Cost;
info.PilotRule='scale2'; info.PilotInitialBest=initCost; info.PilotCMARel=cRel; info.PilotLSRel=lRel;
info.CMAESInfo=ic; info.LSHADEInfo=il; info.FinalInfo=iff;
end
