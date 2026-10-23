function [Best,T,info]=PILOT_CEC(f,state,~,N,seed)
%PILOT_CEC  Pilot-racing dual-core optimizer.
%   Both cores receive a short, equal pilot budget.  The core with the
%   better verified pilot best is selected and rerun for the remaining
%   budget.  No distribution, population, or archive is transferred.
if ~isfield(state,'pilotFrac') || isempty(state.pilotFrac), state.pilotFrac=0.05; end
pilotRule='best'; if isfield(state,'pilotRule') && ~isempty(state.pilotRule), pilotRule=lower(char(state.pilotRule)); end
fid=0; if isfield(state,'functionID') && ~isempty(state.functionID), fid=state.functionID; end
budget=state.maxEvaluations; Bp=max(N,round(state.pilotFrac*budget));
Brem=budget-2*Bp; assert(Brem>=N,'pilot leaves too little budget');
s=state; s.maxEvaluations=Bp;
[Bc,Tc,ic]=CMAES_CEC(f,s,[],N,seed+111111);
[Bl,Tl,il]=LSHADE_CEC(f,s,[],N,seed+777777);
initCost=Tc(min(N,numel(Tc))); cErr=max(0,Bc.Cost-100*fid); lErr=max(0,Bl.Cost-100*fid); initErr=max(1,initCost-100*fid);
if strcmp(pilotRule,'scale')
    chooseLS=(lErr<cErr) && (lErr/initErr>5e-8) && (cErr/initErr<1e-3);
elseif strcmp(pilotRule,'scale2')
    cRel=cErr/initErr; lRel=lErr/initErr;
    chooseLS=(lErr<cErr) && (lRel>5e-9) && (cRel>1e-7) && (cRel<1e-3);
else
    chooseLS=Bl.Cost<Bc.Cost;
end
if chooseLS
    winner='LSHADE'; pilotBest=Bl; Bpilot=Tl;
else
    winner='CMAES'; pilotBest=Bc; Bpilot=Tc;
end
sf=state; sf.maxEvaluations=Brem;
if strcmp(winner,'CMAES')
    [Bf,Tf,iff]=CMAES_CEC(f,sf,[],N,seed+333333);
else
    [Bf,Tf,iff]=LSHADE_CEC(f,sf,[],N,seed+333333);
end
if pilotBest.Cost<Bf.Cost, Best=pilotBest; else, Best=Bf; end
T=[Tc(:);Tl(:);Tf(:)]; T=min(T,Best.Cost); T=cummin(T);
if numel(T)>budget, T=T(1:budget); elseif numel(T)<budget, T(end+1:budget)=T(end); end
T(end)=Best.Cost;
info.Algorithm='PILOT'; info.Evaluations=budget; info.Rounds=ic.Rounds+il.Rounds+iff.Rounds;
info.PilotFE=Bp; info.FinalFE=Brem; info.CMAESPilot=Bc.Cost; info.LSHADEPilot=Bl.Cost;
info.Winner=winner; info.FinalCoreCost=Bf.Cost; info.PilotBest=pilotBest.Cost;
info.PilotRule=pilotRule; info.PilotInitialBest=initCost; info.PilotCMARel=cErr/initErr; info.PilotLSRel=lErr/initErr;
info.CMAESInfo=ic; info.LSHADEInfo=il; info.FinalInfo=iff;
end
