function Ypos=salsRebuildPos(U,aA,A,B,Dl,Xp,lb,ub,opt,trig,Sd)
%SALSREBUILDPOS  Vectorised rebuild of the selected G1 candidates from a 6D uniform block.
%   U    : nS x 6D uniform coefficient block (row k = coefficients of selected G1 candidate k)
%   Xp   : nS x D pre-evaluation parent ("search cursor") positions Xv(par(g1sel),:)
%   trig : nS x 1 STEER trigger indicators, Sd : nS x D random directions (drawn in batch by the
%          caller).  Elementwise arithmetic is identical to the pre-optimisation per-candidate
%          salsPos() loop; verified by tests/test_sals_rebuild_equivalence.m for identical injected
%          coefficients / triggers / directions in 300 random trials.
nS=size(U,1); D=numel(lb);
A1=2*aA*U(:,1:D)-aA;          C1=2*U(:,D+1:2*D);
A2=2*aA*U(:,2*D+1:3*D)-aA;    C2=2*U(:,3*D+1:4*D);
A3=2*aA*U(:,4*D+1:5*D)-aA;    C3=2*U(:,5*D+1:6*D);
X1=A.Vector -A1.*abs(C1.*A.Vector -Xp);
X2=B.Vector -A2.*abs(C2.*B.Vector -Xp);
X3=Dl.Vector-A3.*abs(C3.*Dl.Vector-Xp);
Ypos=(X1+X2+X3)/3;
if nS>0 && opt.succSteer>0
    % norm() 使用缩放求和，与 sqrt(sum(...)) 在末位可能不同；逐候选调用以与优化前逐位一致。
    nrm=zeros(nS,1); stepv=zeros(nS,1);
    for kk=1:nS
        nrm(kk)=norm(Sd(kk,:));
        stepv(kk)=norm(Ypos(kk,:)-Xp(kk,:));
    end
    unit=Sd./max(nrm,realmin);
    Ypos=Ypos+trig.*((opt.steerLambda*unit).*stepv);
end
Ypos=min(max(Ypos,lb),ub);
end
