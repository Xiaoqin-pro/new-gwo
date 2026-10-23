function [Best,T,info]=PILOT_JSO_CEC(f,state,~,N,seed)
%PILOT_JSO_CEC  Scale-normalized pilot race between CMA and jSO.
if ~isfield(state,'pilotFrac') || isempty(state.pilotFrac), state.pilotFrac=0.20; end
fid=0; if isfield(state,'functionID') && ~isempty(state.functionID), fid=state.functionID; end
budget=state.maxEvaluations; Bp=max(N,round(state.pilotFrac*budget)); Brem=budget-2*Bp; assert(Brem>=N);
s=state; s.maxEvaluations=Bp; [Bc,Tc,ic]=CMAES_CEC(f,s,[],N,seed+111111); [Bj,Tj,ij]=jSO_CEC(f,s,[],N,seed+777777);
initCost=Tc(min(size(state.initialPopulation,1),numel(Tc))); cErr=max(0,Bc.Cost-100*fid); jErr=max(0,Bj.Cost-100*fid); initErr=max(1,initCost-100*fid); cRel=cErr/initErr; jRel=jErr/initErr;
chooseJ=(jErr<cErr) && (jRel>5e-9) && (cRel>1e-7) && (cRel<1e-3);
if chooseJ, winner='jSO'; pilotBest=Bj; else, winner='CMAES'; pilotBest=Bc; end
s2=state; s2.maxEvaluations=Brem;
if strcmp(winner,'CMAES')
 [Bf,Tf,iff]=CMAES_CEC(f,s2,[],N,seed+333333);
else
 [Bf,Tf,iff]=jSO_CEC(f,s2,[],N,seed+333333);
end
if pilotBest.Cost<Bf.Cost, Best=pilotBest; else, Best=Bf; end
T=[min(Tc(:),Best.Cost);min(Tj(:),Best.Cost);min(Tf(:),Best.Cost)]; T=cummin(T); if numel(T)>budget,T=T(1:budget); elseif numel(T)<budget,T(end+1:budget)=T(end); end; T(end)=Best.Cost;
info.Algorithm='PILOT-JSO'; info.Evaluations=budget; info.Rounds=ic.Rounds+ij.Rounds+iff.Rounds; info.PilotFE=Bp; info.FinalFE=Brem; info.CMAESPilot=Bc.Cost; info.jSOPilot=Bj.Cost; info.Winner=winner; info.PilotBest=pilotBest.Cost; info.PilotRule='scale2'; info.PilotInitialBest=initCost; info.PilotCMARel=cRel; info.PilotJSORel=jRel; info.CMAInfo=ic; info.JSOInfo=ij; info.FinalInfo=iff;
end
