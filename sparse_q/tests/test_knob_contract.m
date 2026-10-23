function test_knob_contract()
%TEST_KNOB_CONTRACT  All-off must be bitwise identical to SGWO_STEER3; each knob must act.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config(); addpath(fullfile(cfg.root,'src'),fullfile(root,'src')); cd(cfg.cecDir);
D=30; N=50; budget=3000; seed=3986; fid=7;
rng(261013000+fid*10000+seed,'twister'); pool=-100+200*rand(50,D);
base=struct('initialPopulation',pool,'lowerBound',-100*ones(1,D),'upperBound',100*ones(1,D), ...
 'maxEvaluations',budget,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
 'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
 'fillerSteer',0,'evalOrder','index');
fc=@(x)CEC2017Function(x,fid);
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BO,TO,iO]=SGWO_KNOB(fc,base,[],N,seed+1000000);
assert(isequal(TF,TO) && BF.Cost==BO.Cost,'all-off differs from SGWO_STEER3');
fprintf('  all-off  BITWISE EQUAL\n');
% 冻结的评价顺序本身就是"G1 -> 填充 -> E"（sel 按池索引排序），因此 g1first 应与冻结逐位相同
s=base; s.evalOrder='g1first';
[Bg,Tg]=SGWO_KNOB(fc,s,[],N,seed+1000000);
assert(isequal(TF,Tg) && BF.Cost==Bg.Cost,'g1first must equal the frozen order (it is the natural pool order)');
fprintf('  g1first  BITWISE EQUAL (frozen order is already G1-first)\n');
for c={ {1,'index','fillerSteer'},{0,'efirst','efirst'},{1,'efirst','fillerSteer+efirst'} }
    s=base; s.fillerSteer=c{1}{1}; s.evalOrder=c{1}{2};
    [B,T,i]=SGWO_KNOB(fc,s,[],N,seed+1000000);
    assert(i.Evaluations==budget,'FE mismatch %s',c{1}{3});
    assert(~isequal(TF,T),'%s produced identical trace',c{1}{3});
    fprintf('  %-20s ok FE=%d fillerSteerN=%d applied=%d cost=%.6g\n',c{1}{3},i.Evaluations,i.FillerSteerN,i.FillerSteerApplied,B.Cost);
end
fprintf('test_knob_contract PASS.\n');
end
