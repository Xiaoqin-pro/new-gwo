function test_dlh_contract()
%TEST_DLH_CONTRACT  none/audit must be bitwise identical to the frozen final algorithm.
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
    s=base; s.dlhMode=mode{1};
    [B,T,i1]=SGWO_DLH(fc,s,[],N,seed+1000000);
    ok=isequal(TA,T) && BA.Cost==B.Cost;
    fprintf('  %-7s %s | dlhN=%d neighMean=%.2f zeroFrac=%.3f degFrac=%.3f dispMed=%.4f vsGwoMed=%.4f vsEMed=%.4f gwoVsEMed=%.4f\n', ...
        mode{1},ternary(ok,'BITWISE EQUAL','DIFFERS'),i1.DlhN,i1.DlhNeighMean,i1.DlhNeighZeroFrac, ...
        i1.DlhDegFrac,i1.DlhDispMed,i1.DlhVsGwoMed,i1.DlhVsEMed,i1.DlhGwoVsEMed);
    assert(ok,'DLH %s is not bitwise identical',mode{1});
end
for mode={'sparse','global'}
    s=base; s.dlhMode=mode{1};
    [B,T,i2]=SGWO_DLH(fc,s,[],N,seed+1000000);
    assert(i2.Evaluations==budget && all(diff(T)<=0),sprintf('%s run broken',mode{1}));
    fprintf('  %-7s ok FE=%d dlhN=%d cost=%.6g\n',mode{1},i2.Evaluations,i2.DlhN,B.Cost);
end
fprintf('test_dlh_contract PASS.\n');
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
