function test_tsdr_active_contract()
%TEST_TSDR_ACTIVE_CONTRACT  TSD-base vs TSD-R active contract.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
cd(cfg.cecDir);
D=30; N=50; budget=5000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget, ...
    'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'tsdMode','base');
s0=base; s0.tsdrMode='none';
s1=base; s1.tsdrMode='on'; s1.tsdrConsecFail=3; s1.tsdrGainIQR=1;
fc=@(x)CEC2017Function(x,fid);
[B0,T0,i0]=SGWO_TSD(fc,s0,[],N,seed+1000000);
[B1,T1,i1]=SGWO_TSD(fc,s1,[],N,seed+1000000);
assert(i0.Evaluations==budget && i1.Evaluations==budget,'FE mismatch');
assert(i1.TsdrRecoveries>0,'TSD-R never recovered');
fprintf('  base ok cost=%.6g recoveries=0 diff=0\n',B0.Cost);
fprintf('  tsdr ok cost=%.6g recoveries=%d diff=%d\n',B1.Cost,i1.TsdrRecoveries,~isequal(T0,T1));
fprintf('test_tsdr_active_contract PASS: TSD-base/TSD-R exact FE and recovery fired.\n');
end
