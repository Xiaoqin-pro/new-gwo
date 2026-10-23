function test_esteer_contract()
%TEST_ESTEER_CONTRACT  E-STEER must be bitwise inert when off, and must actually act when on.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','none','sdirSource','random','succSteer',0,'steerLambda',0.5,'esteerMode','none');
fc=@(x)CEC2017Function(x,fid);
% (1) E-STEER off, frozen G1+E  -> must equal SGWO_STEER3 with steerMode 'none'
[B0,T0]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[Be,Te]=SGWO_ESTEER(fc,base,[],N,seed+1000000);
assert(isequal(T0,Te) && B0.Cost==Be.Cost && B0.Cost==Be.Cost,'E-STEER off differs from frozen G1+E (steer off)');
fprintf('  E-STEER off (G1+E)      : BITWISE EQUAL to SGWO_STEER3(steer off)\n');
% (2) E-STEER off, frozen final (G1-STEER perwolf) -> must equal SGWO_STEER3 perwolf
sF=base; sF.steerMode='perwolf'; sF.succSteer=0.5;
[BF,TF]=SGWO_STEER3(fc,sF,[],N,seed+1000000);
sF2=sF; sF2.esteerMode='none';
[BF2,TF2]=SGWO_ESTEER(fc,sF2,[],N,seed+1000000);
assert(isequal(TF,TF2) && BF.Cost==BF2.Cost,'E-STEER off differs from SGWO_STEER3(perwolf)');
fprintf('  E-STEER off (final)     : BITWISE EQUAL to SGWO_STEER3(perwolf) = frozen final\n');
% (3) E-STEER on must act: counters > 0, exact FE, monotone trace, and a different trace
cases={'B: G1off/Eon',false; 'C: G1on/Eon',true};
for c=1:size(cases,1)
    s=base; s.esteerMode='rand';
    if cases{c,2}, s.steerMode='perwolf'; s.succSteer=0.5; refCost=BF.Cost; refT=TF;
    else, refCost=B0.Cost; refT=T0; end
    [Bx,Tx,ix]=SGWO_ESTEER(fc,s,[],N,seed+1000000);
    assert(ix.Evaluations==budget && all(diff(Tx)<=0),'E-STEER run broken (%s)',cases{c,1});
    assert(ix.EsteerOn==1 && ix.EsteerGen>0 && ix.EsteerTrig>0,'E-STEER did not trigger (%s)',cases{c,1});
    assert(~isequal(Tx,refT),'E-STEER on but trace identical to its E-STEER-off arm (%s)',cases{c,1});
    assert(ix.EsteerTrigRate>0.4 && ix.EsteerTrigRate<0.6,'E-STEER trigger rate off target: %.3f',ix.EsteerTrigRate);
    fprintf('  %-14s: ok FE=%d gen=%d trig=%d (%.1f%%) stepMean=%.4g cost=%.6g (off-arm %.6g)\n', ...
        cases{c,1},ix.Evaluations,ix.EsteerGen,ix.EsteerTrig,100*ix.EsteerTrigRate,ix.EsteerStepMean,Bx.Cost,refCost);
end
fprintf('test_esteer_contract PASS.\n');
end
