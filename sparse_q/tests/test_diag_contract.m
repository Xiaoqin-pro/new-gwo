function test_diag_contract()
%TEST_DIAG_CONTRACT  SGWO_DIAG must be bitwise identical to SGWO_STEER3 and must fill its counters.
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
[BF,TF]=SGWO_STEER3(fc,base,[],N,seed+1000000);
[BD,TD,i]=SGWO_DIAG(fc,base,[],N,seed+1000000);
assert(isequal(TF,TD) && BF.Cost==BD.Cost,'DIAG differs from SGWO_STEER3');
assert(i.Evaluations==budget,'FE mismatch');
assert(sum(i.DiagEval(:))>0,'no per-class evaluations logged');
fprintf('  BITWISE EQUAL, FE=%d, logged evals=%d\n',i.Evaluations,sum(i.DiagEval(:)));
names={'G1','filler','E-shell','E-2c'};
for c=1:4
    e=sum(i.DiagEval(:,c)); gb=sum(i.DiagGB(:,c)); ar=sum(i.DiagArc(:,c)); po=sum(i.DiagPop(:,c));
    fprintf('  %-8s evals=%5d  GB=%.4f  ARC=%.4f  POP=%.4f\n',names{c},e,gb/max(e,1),ar/max(e,1),po/max(e,1));
end
fprintf('  coverage: lifetimes=%d zero-eval=%.3f mean evals/life=%.2f\n',i.DiagLifeN, ...
    i.DiagZeroEval/max(i.DiagLifeN,1), i.DiagEvalSum/max(i.DiagLifeN,1));
fprintf('  lifetime histogram (0,1,2,3-4,5-9,10+): %s\n',mat2str(i.DiagLifeEval));
fprintf('  GB rate by decile E-shell : %s\n',mat2str(round(1000*i.DiagGB(:,3)./max(i.DiagEval(:,3),1))'));
fprintf('  GB rate by decile E-2c    : %s\n',mat2str(round(1000*i.DiagGB(:,4)./max(i.DiagEval(:,4),1))'));
fprintf('test_diag_contract PASS.\n');
end
