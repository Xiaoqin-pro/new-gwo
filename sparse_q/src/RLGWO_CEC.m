function [Best,T,info]=RLGWO_CEC(f,state,~,N,seed)
%RLGWO_CEC  MATLAB port of the RL-LGWO author implementation
%   (mroayaei/RL-LGWO, Optimizers/ProposedMethod.py; Maleki, Roayaei,
%    Mirjalili, Knowledge-Based Systems 2025, doi:10.1016/j.knosys.2025.114471)
%
%   移植规则（如实标注）：
%   * 逐机制移植：领导者级 3 态×3 动作 Q 表（动作=两组领导者扰动/GWO 聚合），
%     每狼 16 态×4 动作 Q 表（动作=移动权重与 a 调度的组合），与源码一致；
%     参数同源码：lr=0.01、gamma=0.85、eps 1.0→0.15（每代 ×0.995）。
%   * 原作者 Python 实现存在**重复评价**（同一位置反复调用 objf）。本移植使用
%     评价缓存：同一位置只真实评价一次；所有**新位置**的真实评价全部计费，
%     总预算与其它算法完全一致（budget 真 FE）。因此本移植每代 ≈ N 个真实
%     评价 + 0–3 个领导者候选评价，功能等价而 FE 记账严格。
%   * α/β/δ 仅由真实评价的新位置更新；未评价位置不进入任何排序。
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D));
Beta=Alpha; Delta=Alpha;

numActions=4; numStates=16;
Q=zeros(numStates,numActions);
lastState=zeros(N,1);
ring=zeros(N,3); ringCount=zeros(N,1);
lrQ=0.01; gammaQ=0.85; epsW=1.0; decay=0.995; minEps=0.15;
stateUpdate=0;
qL=zeros(3,3);
aGlobal=2.0;

gb=inf; fe=0;
wolfFit=inf(N,1);
for i=1:N
    v=f(X(i,:));
    fe=fe+1; gb=min(gb,v); T(fe)=gb;
    wolfFit(i)=v;
    [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,X(i,:),v);
end
Positions=X;

it=0; maxIt=1e6;
while fe<budget
    it=it+1;
    if it>maxIt, break; end
    prog=fe/budget;
    % ---------- 领导者级 RL 动作 ----------
    if rand()<epsW
        action_update=randi(3)-1;
    else
        [~,action_update]=max(qL(stateUpdate+1,:)); action_update=action_update-1;
    end
    next_state=2; reward=-2;
    if action_update==2
        leaders={Alpha,Beta,Delta};
        for k=1:3
            if fe>=budget, break; end
            xk=leaders{k}.Vector;
            A1=aGlobal*(2*rand(1,D)-1); C1=2*rand(1,D);
            A2=aGlobal*(2*rand(1,D)-1); C2=2*rand(1,D);
            A3=aGlobal*(2*rand(1,D)-1); C3=2*rand(1,D);
            X1=Alpha.Vector-A1.*abs(C1.*Alpha.Vector-xk);
            X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -xk);
            X3=Delta.Vector-A3.*abs(C3.*Delta.Vector -xk);
            Xnew=min(max((X1+X2+X3)/3,lb),ub);
            oldF=leaders{k}.Cost;
            v=f(Xnew); fe=fe+1; gb=min(gb,v); T(fe)=gb;
            if oldF>v
                leaders{k}=struct('Cost',v,'Vector',Xnew);
                if k==1
                    reward=reward+(oldF-v); next_state=0;
                elseif k==2
                    reward=reward+5; if next_state==2, next_state=1; end
                else
                    reward=reward+3; if next_state==2, next_state=1; end
                end
            end
        end
        Alpha=leaders{1}; Beta=leaders{2}; Delta=leaders{3};
    else
        [Alpha,Beta,Delta,reward,next_state,fe,T,gb]=leaderAction(action_update,aGlobal, ...
            f,Alpha,Beta,Delta,lb,ub,fe,budget,T,D,gb);
    end
    if Beta.Cost<Alpha.Cost, tmp=Alpha; Alpha=Beta; Beta=tmp; end
    if Delta.Cost<Beta.Cost
        tmp=Beta; Beta=Delta; Delta=tmp;
        if Beta.Cost<Alpha.Cost, tmp=Alpha; Alpha=Beta; Beta=tmp; end
    end
    % ---------- 每狼 RL 移动 ----------
    tt=2*cos((pi/2)*prog);
    bb=abs(cos(prog*pi))*2;
    for i=1:N
        if fe>=budget, break; end
        st=lastState(i)+1;
        if rand()<epsW
            action=randi(numActions)-1;
        else
            [~,action]=max(Q(st,:)); action=action-1;
        end
        switch action
            case 0, a=tt; ad=0.6; bd=0.3; cd=0.1;
            case 1, a=tt; ad=1; bd=1; cd=1;
            case 2, a=bb; ad=0.6; bd=0.3; cd=0.1;
            otherwise, a=bb; ad=1; bd=1; cd=1;
        end
        aGlobal=a;
        xi=Positions(i,:); old_fit=wolfFit(i);   % 缓存：该位置最后一次真实评价
        for j=1:D
            r1=rand(); r2=rand(); A1=2*a*r1-a; C1=2*r2;
            X1=Alpha.Vector(j)-A1*abs(C1*Alpha.Vector(j)-xi(j));
            r1=rand(); r2=rand(); A2=2*a*r1-a; C2=2*r2;
            X2=Beta.Vector(j)-A2*abs(C2*Beta.Vector(j)-xi(j));
            r1=rand(); r2=rand(); A3=2*a*r1-a; C3=2*r2;
            X3=Delta.Vector(j)-A3*abs(C3*Delta.Vector(j)-xi(j));
            xi(j)=((ad*X1)+(bd*X2)+(cd*X3))/(ad+bd+cd);
        end
        xi=min(max(xi,lb),ub);
        v=f(xi); fe=fe+1; gb=min(gb,v); T(fe)=gb;
        [Alpha,Beta,Delta]=insertLeader(Alpha,Beta,Delta,xi,v);
        Positions(i,:)=xi; wolfFit(i)=v;
        if action==0 || action==2, ttag=5; else, ttag=2; end
        if ringCount(i)<3
            ring(i,:)=[ring(i,2:3), 2*(old_fit>v)-1];
            ringCount(i)=ringCount(i)+1;
        else
            ring(i,:)=[ring(i,2:3), 2*(old_fit>v)-1];
        end
        if it>3
            lastState(i)=mapState(ring(i,:),ttag);
        else
            lastState(i)=0;
        end
        if old_fit>v, rew=old_fit-v; else, rew=0; end
        Q(st,action+1)=Q(st,action+1)+lrQ*(rew+gammaQ*max(Q(lastState(i)+1,:))-Q(st,action+1));
    end
    epsW=max(minEps,epsW*decay);
    qL(stateUpdate+1,action_update+1)=qL(stateUpdate+1,action_update+1)+lrQ*(reward+gammaQ*max(qL(next_state+1,:))-qL(stateUpdate+1,action_update+1));
    stateUpdate=next_state;
end

Best=struct('Cost',Alpha.Cost,'Vector',Alpha.Vector);
info=struct('Evaluations',fe,'Algorithm','RLGWO-CEC-port','Rounds',it);
end

function s=mapState(ring,t)
% 16 态映射（与源码 state_mapping 顺序一致）：3 个改进符号（1 在前）× t∈{5,2}
pos=(ring(1)<0)*4+(ring(2)<0)*2+(ring(3)<0)*1;
s=pos*2+(t==2);
end

function [A,B,Dl,reward,next_state,fe,T,gb]=leaderAction(action,aGlobal,f,A,B,Dl,lb,ub,fe,budget,T,D,gb)
reward=-2; next_state=2;
if fe>=budget, return; end
if aGlobal<0.7, q=1; else, q=-1; end
if action==0
    r=gamrnd(1.5,0.4,1,D);
else
    r=exprnd(1,1,D);
end
xp=min(max(A.Vector-q*A.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; gb=min(gb,v); T(fe)=gb;
if A.Cost>v, A=struct('Cost',v,'Vector',xp); reward=reward+30; next_state=0; end
xp=min(max(B.Vector-B.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; gb=min(gb,v); T(fe)=gb;
if B.Cost>v
    B=struct('Cost',v,'Vector',xp); reward=reward+15;
    if next_state==2, next_state=1; end
end
xp=min(max(Dl.Vector-Dl.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; gb=min(gb,v); T(fe)=gb;
if Dl.Cost>v
    Dl=struct('Cost',v,'Vector',xp); reward=reward+5;
    if next_state==2, next_state=1; end
end
end

function [A,B,Dl]=insertLeader(A,B,Dl,x,v)
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end

