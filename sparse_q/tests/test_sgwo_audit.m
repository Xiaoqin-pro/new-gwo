function test_sgwo_audit()
%TEST_SGWO_AUDIT  Bitwise pipeline audits against the frozen implementations.
% (1) SGWO('dense-async') must equal frozen GWO.m bit-for-bit (sphere + CEC);
% (2) frozen ANGWO and GWO remain callable read-only from this branch;
% (3) sparse modes complete with exact budget on CEC2017.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
fprintf('== test_sgwo_audit ==\n');

% ---- (1a) sphere: dense-async == GWO bitwise ----
D=5; N=8; budget=640;
rng(21,'twister'); X0=-5+10*rand(N,D);
st=struct('initialPopulation',X0,'lowerBound',-5*ones(1,D), ...
    'upperBound',5*ones(1,D),'maxEvaluations',budget);
f=@(x)sum(x.^2)+0.25*sum(sin(3*x));
[BG,TG]=GWO(f,st,[],N,99);
sa=st; sa.mode='dense-async';
[BA,TA]=SGWO(f,sa,[],N,99);
assert(isequal(TG,TA),'dense-async must equal GWO bitwise (sphere)');
assert(BG.Cost==BA.Cost && isequal(BG.Vector,BA.Vector),'best must match (sphere)');
fprintf('  sphere: SGWO(dense-async) == GWO bitwise (best=%.10g) ok\n',BA.Cost);

% ---- (1b) CEC2017 F1: dense-async == GWO bitwise ----
cd(cfg.cecDir);
D=30; budget=3000; fid=1;
rng(261013000+fid*10000+3001,'twister'); pool=-100+200*rand(50,D);
st=struct('initialPopulation',pool(1:50,:),'lowerBound',-100*ones(1,D), ...
    'upperBound',100*ones(1,D),'maxEvaluations',budget);
fc=@(x)CEC2017Function(x,fid);
[BG,TG]=GWO(fc,st,[],50,3001+1000000);
sa=st; sa.mode='dense-async';
[BA,TA]=SGWO(fc,sa,[],50,3001+1000000);
assert(isequal(TG,TA),'dense-async must equal GWO bitwise (CEC F1)');
fprintf('  CEC F1 D30 3k: bitwise equal (best=%.10g) ok\n',BA.Cost);

% ---- (2) frozen read-only controls still work ----
sb=st; sb.exploreMode='fixed'; sb.exploreShare=0.20; sb.roverCenter='alpha'; sb.roverDest='random';
[BestA,TA,infoA]=ANGWO(fc,sb,[],50,3001+1000000);
assert(infoA.Evaluations==budget,'ANGWO FE broken');
assert(all(diff(TA)<=0));
fprintf('  frozen ANGWO callable: FE=%d best=%.6g ok\n',infoA.Evaluations,BestA.Cost);

% ---- (3) sparse modes exact budget on CEC ----
sc=st; sc.mode='sparse'; sc.K=50; sc.screenPolicy='directed'; sc.quotaPolicy='fixed'; sc.quotaFixed=0.5;
[Bs,Ts,is]=SGWO(fc,sc,[],50,3002+1000000);
assert(is.Evaluations==budget,'sparse FE broken');
assert(all(diff(Ts)<=0) && Ts(end)==Bs.Cost);
sd=st; sd.mode='dense-sync';
[Bd,~,idd]=SGWO(fc,sd,[],50,3003+1000000);
assert(idd.Evaluations==budget,'dense-sync FE broken');
fprintf('  sparse K=50 FE=%d best=%.6g; dense-sync best=%.6g ok\n',is.Evaluations,Bs.Cost,Bd.Cost);
fprintf('== test_sgwo_audit PASS ==\n');
end
