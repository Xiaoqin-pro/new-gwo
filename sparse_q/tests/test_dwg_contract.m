function test_dwg_contract()
%TEST_DWG_CONTRACT  off is bitwise equal; dynamic wolf groups actuate.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=6000; seed=3996; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
s=base; s.dwgMode='off';
[B0,T0,i0]=SGWO_DWG(fc,s,[],N,seed+1000000);
assert(isequal(TF,T0) && BF.Cost==B0.Cost,'off differs from SGWO_STEER3');
fprintf('  off   BITWISE EQUAL | FE=%d\n',i0.Evaluations);
s=base; s.dwgMode='on'; s.dwgN1=25;
[B,T,i]=SGWO_DWG(fc,s,[],N,seed+1000000);
assert(i.Evaluations==budget,'FE mismatch on');
assert(~isequal(TF,T),'on produced identical trace');
assert(i.DwgApplied>0,'DWG did not apply');
fprintf('  on    ok FE=%d applied=%d success=%d n1=%d cost=%.6g\n',i.Evaluations,i.DwgApplied,i.DwgSuccess,i.DwgN1,B.Cost);
fprintf('test_dwg_contract PASS.\n');
end
