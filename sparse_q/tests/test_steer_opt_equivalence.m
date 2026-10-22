function test_steer_opt_equivalence()
%TEST_STEER_OPT_EQUIVALENCE  SGWO_STEER2 must be BITWISE identical to SGWO_STEER in every mode.
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
cfgs={ {'perwolf','random',0.5,0,0}, {'perwolf','random',0.0,0,0}, {'stj','random',0.5,500,0.02}, ...
       {'dir','g1',0.5,0,0}, {'vec','random',1.0,0,0}, {'rand','random',0.5,0,0} };
for k=1:numel(cfgs)
    c=cfgs{k}; s1=base; s1.steerMode=c{1}; s1.sdirSource=c{2}; s1.succSteer=c{3};
    s1.steerLambda=0.5; s1.stjTauMin=c{4}; s1.stjTauFrac=c{5};
    s2=s1;
    [B1,T1]=SGWO_STEER(fc,s1,[],N,seed+1000000);
    [B2,T2]=SGWO_STEER2(fc,s2,[],N,seed+1000000);
    [B3,T3]=SGWO_STEER3(fc,s2,[],N,seed+1000000);
    ok2=isequal(T1,T2) && B1.Cost==B2.Cost;
    ok3=isequal(T1,T3) && B1.Cost==B3.Cost;
    fprintf('  %-8s %-7s p=%.1f tau=%d: STEER2 %s | STEER3 %s (cost=%.10g / %.10g / %.10g)\n', ...
        c{1},c{2},c{3},c{4},ternary(ok2,'equal','DIFFERS'),ternary(ok3,'equal','DIFFERS'),B1.Cost,B2.Cost,B3.Cost);
    assert(ok2,'SGWO_STEER2 differs from SGWO_STEER for %s/%s',c{1},c{2});
    assert(ok3,'SGWO_STEER3 differs from SGWO_STEER for %s/%s',c{1},c{2});
end
fprintf('test_steer_opt_equivalence PASS: STEER2/STEER3 are bitwise identical to STEER in all modes.\n');
% wall-clock comparison of the whole algorithm (D=50, 100k FE)
D2=50; budget2=100000; pool2=-100+200*rand(50,D2);
for fid2=[1 13 30]
    rng(261013000+fid2*10000+3986,'twister'); pool2=-100+200*rand(50,D2);
    b=struct('initialPopulation',pool2,'lowerBound',-100*ones(1,D2),'upperBound',100*ones(1,D2), ...
        'maxEvaluations',budget2,'mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
        'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5);
    fc2=@(x)CEC2017Function(x,fid2);
    t1=tic; [Bx,Tx]=SGWO_STEER(fc2,b,[],N,3986+1000000); s1=toc(t1);
    t2=tic; [By,Ty]=SGWO_STEER3(fc2,b,[],N,3986+1000000); s2=toc(t2);
    assert(isequal(Tx,Ty) && Bx.Cost==By.Cost,'timing pair differs (F%d)',fid2);
    fprintf('  F%-3d F1+E+STEER: %.2f s -> %.2f s (%.1f%% faster, bitwise identical)\n',fid2,s1,s2,100*(s1-s2)/s1);
end
end

function out=ternary(cond,a,b)
if cond, out=a; else, out=b; end
end
