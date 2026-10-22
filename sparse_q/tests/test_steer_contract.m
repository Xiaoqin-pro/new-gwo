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
fprintf('test_steer_contract PASS.\n');
end
