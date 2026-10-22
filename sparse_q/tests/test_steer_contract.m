function test_steer_contract()
%TEST_STEER_CONTRACT  none must stay bitwise identical; rand/dir exact FE and active.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0);
fc=@(x)CEC2017Function(x,fid);
[BA,TA]=SGWO_ABLATION(fc,base,[],N,seed+1000000);
sN=base; sN.steerMode='none';
[BN,TN]=SGWO_STEER(fc,sN,[],N,seed+1000000);
assert(isequal(TA,TN) && BA.Cost==BN.Cost,'STEER none differs from frozen scaffold');
fprintf('  none ok FE=%d cost=%.6g\n',budget,BN.Cost);
for spec={ {'rand',0.5,'random'}, {'dir',0.5,'g1'} }
    sp=spec{1}; s=base; s.steerMode=sp{1}; s.succSteer=sp{2}; s.steerLambda=0.5; s.sdirSource=sp{3};
    [B,T,inf1]=SGWO_STEER(fc,s,[],N,seed+1000000);
    assert(inf1.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',sp{1}));
    assert(inf1.SteerTriggers>0,'no perturbation trigger');
    assert(~isequal(T,TA),sprintf('%s did not change the trace',sp{1}));
    fprintf('  %-4s ok FE=%d triggers=%d applied=%d rate=%.3f cost=%.6g\n', ...
        sp{1},inf1.Evaluations,inf1.SteerTriggers,inf1.SteerApplied,inf1.SteerRate,B.Cost);
end
sV=base; sV.steerMode='vec'; sV.succSteer=1;
[BV,TV,iV]=SGWO_STEER(fc,sV,[],N,seed+1000000);
assert(iV.Evaluations==budget && iV.SteerApplied==0,'vec arm must run without perturbation');
fprintf('  vec  ok FE=%d applied=%d cost=%.6g (traceless control for rand/dir)\n',iV.Evaluations,iV.SteerApplied,BV.Cost);
s0=base; s0.steerMode='rand'; s0.succSteer=0;
[~,T0]=SGWO_STEER(fc,s0,[],N,seed+1000000);
assert(isequal(T0,TV),'rand with prob 0 must equal the vectorised control trace');
fprintf('  prob=0 rand path == vec control (bitwise)\n');
% perwolf 模式必须与 SGWO_ABLATION 的同一机制逐位一致
for spec={ {'random'}, {'g1'} }
    src=spec{1}{1};
    s1=base; s1.succSteer=0.5; s1.steerLambda=0.5; s1.sdirSource=src;
    [B1,T1]=SGWO_ABLATION(fc,s1,[],N,seed+1000000);
    s2=s1; s2.steerMode='perwolf';
    [B2,T2,i2]=SGWO_STEER(fc,s2,[],N,seed+1000000);
    assert(isequal(T1,T2) && B1.Cost==B2.Cost,sprintf('perwolf %s differs from SGWO_ABLATION',src));
    fprintf('  perwolf %-6s bitwise identical to SGWO_ABLATION (cost=%.6g)\n',src,B2.Cost);
end
% STJ: gate always on must equal the always-on STEER arm (bitwise)
sB=base; sB.steerMode='perwolf'; sB.succSteer=0.5; sB.steerLambda=0.5; sB.sdirSource='random';
[BB,TB]=SGWO_STEER(fc,sB,[],N,seed+1000000);
sOn=base; sOn.steerMode='stj'; sOn.succSteer=0.5; sOn.steerLambda=0.5; sOn.sdirSource='random';
sOn.stjTauMin=0; sOn.stjTauFrac=0;
[Bon,Ton,iOn]=SGWO_STEER(fc,sOn,[],N,seed+1000000);
assert(isequal(TB,Ton) && BB.Cost==Bon.Cost,'STJ with tau=0 must equal the always-on STEER arm');
fprintf('  STJ tau=0  == perwolf STEER (bitwise), gateGens=%d applied=%d\n',iOn.StjGateGens,iOn.StjApplied);
% STJ: gate never on must equal frozen
sOff=base; sOff.steerMode='stj'; sOff.succSteer=0.5; sOff.steerLambda=0.5; sOff.sdirSource='random';
sOff.stjTauMin=1e9; sOff.stjTauFrac=0;
[~,Toff,iOff]=SGWO_STEER(fc,sOff,[],N,seed+1000000);
assert(isequal(TA,Toff),'STJ with tau=inf must equal the frozen scaffold');
fprintf('  STJ tau=inf == frozen (bitwise), gateGens=%d applied=%d\n',iOff.StjGateGens,iOff.StjApplied);
% STJ with the repo stagnation window on a 3000-FE run: exact FE, gate fires, trace differs
sStj=base; sStj.steerMode='stj'; sStj.succSteer=0.5; sStj.steerLambda=0.5; sStj.sdirSource='random';
sStj.stjTauMin=500; sStj.stjTauFrac=0.02;
[Bs,Ts,iS]=SGWO_STEER(fc,sStj,[],N,seed+1000000);
assert(iS.Evaluations==budget && all(diff(Ts)<=0),'STJ run broken');
assert(iS.StjGateGens>0 && iS.StjApplied>0,sprintf('STJ gate never fired (gens=%d applied=%d)',iS.StjGateGens,iS.StjApplied));
fprintf('  STJ tau=500 ok FE=%d gateGens=%d/%d applied=%d cost=%.6g (trace may coincide on a 3k smoke run)\n',iS.Evaluations,iS.StjGateGens,iS.Rounds,iS.StjApplied,Bs.Cost);
% longer budget: the gated perturbation must change the search trajectory
budget2=20000; sBase2=base; sBase2.maxEvaluations=budget2;
[~,T2f]=SGWO_ABLATION(fc,sBase2,[],N,seed+1000000);
s2=base; s2.maxEvaluations=budget2; s2.steerMode='stj'; s2.succSteer=0.5; s2.steerLambda=0.5;
s2.sdirSource='random'; s2.stjTauMin=2000; s2.stjTauFrac=0.02;
[B2,T2,i2]=SGWO_STEER(fc,s2,[],N,seed+1000000);
assert(i2.Evaluations==budget2,'STJ long FE mismatch');
assert(~isequal(T2,T2f),'STJ did not change the search at a 20k budget');
fprintf('  STJ 20k: differs from frozen, gateGens=%d/%d applied=%d\n',i2.StjGateGens,i2.Rounds,i2.StjApplied);
% DSE premise audit must be bitwise identical to the frozen scaffold
sDa=base; sDa.steerMode='dsaudit'; sDa.stjTauMin=2000; sDa.stjTauFrac=0.02; sDa.succSteer=0.5; sDa.sdirSource='random';
[BDa,TDa,iDa]=SGWO_STEER(fc,sDa,[],N,seed+1000000);
assert(isequal(TA,TDa) && BA.Cost==BDa.Cost,'dsaudit differs from frozen scaffold');
fprintf('  dsaudit ok FE=%d (bitwise frozen); arcImp=%d maxArcGap=%d dualFE=%d firstDual=%d\n', ...
    iDa.Evaluations,iDa.DaArcImpCnt,iDa.DaArcGapMax,iDa.DaDualFE,iDa.DaFirstDualFE);
fprintf('test_steer_contract PASS.\n');
end
