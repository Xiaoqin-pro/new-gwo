function test_sals_contract()
%TEST_SALS_CONTRACT  none/audit must stay bitwise identical; iid/lhs must run with exact FE.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BA,TA]=SGWO_STEER3(fc,base,[],N,seed+1000000);
for mode={'none','audit'}
    s=base; s.salsMode=mode{1};
    [B,T,i1]=SGWO_SALS(fc,s,[],N,seed+1000000);
    ok=isequal(TA,T) && BA.Cost==B.Cost;
    fprintf('  %-6s %s | gens=%d nMean=%.2f dispB=%.4f dispC=%.4f shiftB=%.4f shiftC=%.4f stratFrac=%.3f\n', ...
        mode{1},ternary(ok,'BITWISE EQUAL','DIFFERS'),i1.SalsGens,i1.SalsNMean,i1.SalsDispBMean, ...
        i1.SalsDispCMean,i1.SalsShiftBMean,i1.SalsShiftCMean,i1.SalsStratFrac);
    assert(ok,'SALS %s is not bitwise identical',mode{1});
end
% SALS-specific audit on SGWO_SALS
s=base; s.salsMode='audit';
[~,Ta,ia]=SGWO_SALS(fc,s,[],N,seed+1000000);
assert(isequal(TA,Ta),'SGWO_SALS audit differs from the frozen scaffold');
assert(abs(ia.SalsStratFrac-1)<1e-12,sprintf('stratification not realised: %.4f',ia.SalsStratFrac));
fprintf('  SALS audit: gens=%d nMean=%.2f dispB=%.4f dispC=%.4f (C/B-1=%+.1f%%) shiftB=%.4f shiftC=%.4f stratFrac=%.3f\n', ...
    ia.SalsGens,ia.SalsNMean,ia.SalsDispBMean,ia.SalsDispCMean, ...
    100*(ia.SalsDispCMean/max(ia.SalsDispBMean,eps)-1),ia.SalsShiftBMean,ia.SalsShiftCMean,ia.SalsStratFrac);
for mode={'iid','lhs'}
    s=base; s.salsMode=mode{1};
    [B,T,i2]=SGWO_SALS(fc,s,[],N,seed+1000000);
    assert(i2.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',mode{1}));
    fprintf('  %-6s ok FE=%d cost=%.6g\n',mode{1},i2.Evaluations,B.Cost);
end
fprintf('test_sals_contract PASS.\n');
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
