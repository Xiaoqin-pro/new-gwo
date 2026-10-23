function test_idc_contract()
%TEST_IDC_CONTRACT  IDC must be bitwise inert when off, and must act when either fix is enabled.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'idcStableID',0,'idcResetOnRefresh',0,'idcAudit',0);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.idcAudit=1;
[B0,T0,i0]=SGWO_IDC(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'IDC audit (flags off) differs from SGWO_STEER3');
fprintf('  off+audit  BITWISE EQUAL | credTotal=%d wrong=%d (%.2f%%) stale=%d (%.2f%%) refresh=%d leakEv=%d (%.1f%%) leakMass/total=%.2f\n', ...
    i0.IdcCredTotal,i0.IdcWrong,100*i0.IdcWrongRate,i0.IdcStale,100*i0.IdcStaleRate,i0.IdcRefresh, ...
    i0.IdcLeakEvents,100*i0.IdcLeakRate,i0.IdcLeakMassRatio);
assert(i0.IdcCredTotal>0,'audit saw no credit events');
assert(i0.IdcRefresh>0 && i0.IdcLeakEvents>0,'audit found no leak events');
for arms={ {1,1,'ID+Reset'},{1,0,'ID only'},{0,1,'Reset only'} }
    a=arms{1}; s=base; s.idcStableID=a{1}; s.idcResetOnRefresh=a{2};
    [B,T,i]=SGWO_IDC(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch in %s',a{3});
    differs=~isequal(TF,T);
    if a{1}==1   % ID-based routing must change behaviour
        assert(differs,'%s produced an identical trace to frozen',a{3});
    end
    fprintf('  %-10s ok FE=%d traceDiffers=%d wrong=%d stale=%d dropped=%d leakEv=%d leakMass/total=%.2f cost=%.6g\n', ...
        a{3},i.Evaluations,differs,i.IdcWrong,i.IdcStale,i.IdcDropped,i.IdcLeakEvents,i.IdcLeakMassRatio,B.Cost);
end
fprintf('test_idc_contract PASS.\n');
end
