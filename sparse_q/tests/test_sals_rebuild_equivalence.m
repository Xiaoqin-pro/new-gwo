function test_sals_rebuild_equivalence()
%TEST_SALS_REBUILD_EQUIVALENCE  The vectorised rebuild must reproduce the pre-optimisation
%   per-candidate salsPos() loop BITWISE for identical coefficients / STEER triggers / directions.
%   Reference arithmetic = the loop implementation that the P1 draft used (tests/ref/SGWO_SALS_preopt.m).
root=fileparts(fileparts(mfilename('fullpath')));
cfg=newgwo_config();
addpath(fullfile(cfg.root,'src'),fullfile(root,'src'));
D=8; nS=5; lb=-100*ones(1,D); ub=100*ones(1,D);
opt=struct('succSteer',0.5,'steerLambda',0.5);
rng(20261022,'twister');
nCand=0;
for trial=1:300
    A=struct('Vector',-100+200*rand(1,D));
    B=struct('Vector',-100+200*rand(1,D));
    Dl=struct('Vector',-100+200*rand(1,D));
    Xp=-100+200*rand(nS,D); aA=2*rand; U=rand(nS,6*D);
    ss=RandStream('mt19937ar','Seed',trial);
    trig=rand(ss,nS,1)<opt.succSteer; Sd=randn(ss,nS,D);
    Yv=salsRebuildPos(U,aA,A,B,Dl,Xp,lb,ub,opt,trig,Sd);
    Yl=zeros(nS,D);
    for kk=1:nS
        Yl(kk,:)=salsPosRef(U(kk,:),aA,A,B,Dl,Xp(kk,:),trig(kk),Sd(kk,:),opt,lb,ub,D);
    end
    assert(isequal(Yv,Yl),sprintf('trial %d: vectorised rebuild differs from the loop reference',trial));
    nCand=nCand+nS;
end
% also check the degenerate options
opt0=struct('succSteer',0,'steerLambda',0.5);
Yv=salsRebuildPos(U,aA,A,B,Dl,Xp,lb,ub,opt0,false(nS,1),zeros(nS,D));
Yl=zeros(nS,D);
for kk=1:nS, Yl(kk,:)=salsPosRef(U(kk,:),aA,A,B,Dl,Xp(kk,:),false,zeros(1,D),opt0,lb,ub,D); end
assert(isequal(Yv,Yl),'no-STEER case differs');
fprintf('test_sals_rebuild_equivalence PASS: %d candidates bitwise identical to the salsPos loop\n',nCand);
end

function y=salsPosRef(u,aA,A,B,Dl,xw,trig,sd,opt,lb,ub,D)
%SALSPOSREF  Byte-for-byte mirror of the pre-optimisation per-candidate rebuild, with the STEER
%   trigger / direction injected instead of drawn from the stream.
A1=2*aA*u(1:D)-aA;          C1=2*u(D+1:2*D);
A2=2*aA*u(2*D+1:3*D)-aA;    C2=2*u(3*D+1:4*D);
A3=2*aA*u(4*D+1:5*D)-aA;    C3=2*u(5*D+1:6*D);
X1=A.Vector -A1.*abs(C1.*A.Vector -xw);
X2=B.Vector -A2.*abs(C2.*B.Vector -xw);
X3=Dl.Vector-A3.*abs(C3.*Dl.Vector-xw);
y=(X1+X2+X3)/3;
if opt.succSteer>0 && trig
    nrm=norm(sd);
    if nrm>0
        stepv=norm(y-xw);
        y=y+opt.steerLambda*(sd/nrm)*stepv;
    end
end
y=min(max(y,lb),ub);
end
