function [Best,T,info]=RLGWO_CEC(f,state,~,N,seed)
%RLGWO_CEC  RL-LGWO 双模式实现（Maleki, Roayaei, Mirjalili, KBS 2025,
%   doi:10.1016/j.knosys.2025.114471；作者源码 mroayaei/RL-LGWO @1a004c4,
%   Optimizers/ProposedMethod.py）
%
%  模式（state.rlMode）：
%   'author' — 逐字忠实作者开源代码（含其已知缺陷，用于敏感性对照）：
%       * 个体 Q 更新 = 源码字面表达式 Q <- lr*(r + gamma*maxQ)（旧 Q 项相消）
%       * 领导动作 2：leaderpop 为局部列表，更新**不回写** α/β/δ；
%         α 奖励=0（源码先覆盖位置再作差）；β/+5、δ/+3
%       * 领导动作 2 的 A/C 为标量（各维共享）
%       * 领导狼仅在每轮开始按当前种群刷新；个体更新后不刷新
%       * 环形缓冲用源码的“存储槽顺序”语义
%   'paper'  — 按论文方法描述修正：
%       * 标准 TD 个体 Q 更新
%       * 领导动作 2：回写领导；α 奖励 = 旧适应度 - 新适应度
%       * 领导动作 2 的 A/C 逐维（标准 GWO Eq.(8)）
%       * 领导狼在发现更优解时即时更新
%
%  两模式共同适配（仅计费/调度；逐条记录于 docs/14）：
%       * 评价缓存：同一位置只做一次真实评价（作者源码多处重复调用 objf）
%       * 调度变量 l/Max_iter -> 真实 FE 进度 fe/budget（等 FE 协议）
%       * 初始种群由实验框架给定（与全部算法同一初始池）
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
mode='paper'; if isfield(state,'rlMode') && ~isempty(state.rlMode), mode=char(state.rlMode); end
isAuthor=strcmpi(mode,'author');
rng(seed,'twister');
T=nan(budget,1);
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
gb=inf; fe=0; wolfFit=inf(N,1); bVec=X(1,:);
for i=1:N
    v=f(X(i,:)); fe=fe+1; if v<gb, gb=v; bVec=X(i,:); end; T(fe)=gb; wolfFit(i)=v;
    [Alpha,Beta,Delta]=updLeaders(Alpha,Beta,Delta,X(i,:),v,isAuthor);
end
Positions=X;
numActions=4; numStates=16;
Q=zeros(numStates,numActions); lastState=zeros(N,1);
ring=zeros(N,3); ringCnt=zeros(N,1); ringPtr=zeros(N,1);   % 作者语义：槽位存储序
qL=zeros(3,3); stateUpdate=0;
lrQ=0.01; gammaQ=0.85; epsW=1.0; decay=0.995; minEps=0.15;
aGlobal=2.0;
it=0;
while fe<budget
    it=it+1;
    prog=fe/budget;
    % ---- 作者模式：每轮开始按当前种群（缓存值）刷新领导 ----
    if isAuthor
        for i=1:N
            [Alpha,Beta,Delta]=updLeaders(Alpha,Beta,Delta,Positions(i,:),wolfFit(i),true);
        end
    end
    % ---- 领导层 ε-greedy 动作 ----
    if rand()<epsW
        action_update=randi(3)-1;
    else
        [~,ai]=max(qL(stateUpdate+1,:)); action_update=ai-1;
    end
    next_state=2; reward=-2;
    if action_update==2
        for k=1:3
            if fe>=budget, break; end
            switch k
                case 1, Xk=Alpha.Vector; fk=Alpha.Cost;
                case 2, Xk=Beta.Vector;  fk=Beta.Cost;
                otherwise, Xk=Delta.Vector; fk=Delta.Cost;
            end
            if isAuthor
                A1=aGlobal*(2*rand()-1); C1=2*rand();
                A2=aGlobal*(2*rand()-1); C2=2*rand();
                A3=aGlobal*(2*rand()-1); C3=2*rand();
            else
                A1=aGlobal*(2*rand(1,D)-1); C1=2*rand(1,D);
                A2=aGlobal*(2*rand(1,D)-1); C2=2*rand(1,D);
                A3=aGlobal*(2*rand(1,D)-1); C3=2*rand(1,D);
            end
            X1=Alpha.Vector-A1.*abs(C1.*Alpha.Vector-Xk);
            X2=Beta.Vector -A2.*abs(C2.*Beta.Vector -Xk);
            X3=Delta.Vector-A3.*abs(C3.*Delta.Vector-Xk);
            Xnew=min(max((X1+X2+X3)/3,lb),ub);
            v=f(Xnew); fe=fe+1; if v<gb, gb=v; bVec=Xnew; end; T(fe)=gb;
            if fk>v
                if isAuthor   % 局部更新，不回写（源码行为）；α 奖励恒为 0
                    switch k
                        case 1, next_state=0;                    % reward += 0
                        case 2, reward=reward+5; if next_state==2, next_state=1; end
                        otherwise, reward=reward+3; if next_state==2, next_state=1; end
                    end
                else          % 论文修正：回写 + 真实增益奖励
                    switch k
                        case 1, Alpha=struct('Cost',v,'Vector',Xnew);
                            reward=reward+(fk-v); next_state=0;
                        case 2, Beta=struct('Cost',v,'Vector',Xnew);
                            reward=reward+5; if next_state==2, next_state=1; end
                        otherwise, Delta=struct('Cost',v,'Vector',Xnew);
                            reward=reward+3; if next_state==2, next_state=1; end
                    end
                end
            end
        end
    else
        [Alpha,Beta,Delta,reward,next_state,fe,T,gb,bVec]=leaderAction(action_update,aGlobal, ...
            f,Alpha,Beta,Delta,lb,ub,fe,budget,T,D,gb,bVec);
    end
    % ---- 领导排序（作者源码顺序） ----
    if Beta.Cost<Alpha.Cost, tmp=Alpha; Alpha=Beta; Beta=tmp; end
    if Delta.Cost<Beta.Cost
        tmp=Beta; Beta=Delta; Delta=tmp;
        if Beta.Cost<Alpha.Cost, tmp=Alpha; Alpha=Beta; Beta=tmp; end
    end
    % ---- 领导 Q 更新（源码即为标准 TD） ----
    qL(stateUpdate+1,action_update+1)=qL(stateUpdate+1,action_update+1) + ...
        lrQ*(reward+gammaQ*max(qL(next_state+1,:))-qL(stateUpdate+1,action_update+1));
    stateUpdate=next_state;
    % ---- ε 衰减：领导动作之后、个体动作之前（作者源码时机） ----
    epsW=max(minEps,epsW*decay);
    % ---- 个体狼 ----
    tt=2*cos((pi/2)*prog);
    bb=abs(cos(prog*pi))*2;
    for i=1:N
        if fe>=budget, break; end
        st=lastState(i)+1;
        if rand()<epsW
            action=randi(numActions)-1;
        else
            [~,ai]=max(Q(st,:)); action=ai-1;
        end
        switch action
            case 0, a=tt; ad=0.6; bd=0.3; cd=0.1;
            case 1, a=tt; ad=1; bd=1; cd=1;
            case 2, a=bb; ad=0.6; bd=0.3; cd=0.1;
            otherwise, a=bb; ad=1; bd=1; cd=1;
        end
        aGlobal=a;
        xi=Positions(i,:); old_fit=wolfFit(i);
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
        v=f(xi); fe=fe+1; if v<gb, gb=v; bVec=xi; end; T(fe)=gb;
        if ~isAuthor
            [Alpha,Beta,Delta]=updLeaders(Alpha,Beta,Delta,xi,v,false);
        end
        Positions(i,:)=xi; wolfFit(i)=v;
        % 环形缓冲（作者语义：槽位存储序；paper 模式：时序）
        if isAuthor
            if ringCnt(i)<3
                ring(i,ringCnt(i)+1)=2*(old_fit>v)-1; ringCnt(i)=ringCnt(i)+1;
            else
                ring(i,ringPtr(i)+1)=2*(old_fit>v)-1; ringPtr(i)=mod(ringPtr(i)+1,3);
            end
        else
            ring(i,:)=[ring(i,2:3), 2*(old_fit>v)-1];
        end
        if action==0 || action==2, ttag=5; else, ttag=2; end
        if it>3
            ns=mapState(ring(i,:),ttag);
        else
            ns=0;
        end
        rew=max(old_fit-v,0);
        if isAuthor
            Q(st,action+1)=lrQ*(rew+gammaQ*max(Q(ns+1,:)));           % 源码字面式
        else
            Q(st,action+1)=Q(st,action+1)+lrQ*(rew+gammaQ*max(Q(ns+1,:))-Q(st,action+1));
        end
        lastState(i)=ns;
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','RLGWO-CEC','Rounds',it,'Mode',mode);
end

% ==================== 辅助函数 ====================
function s=mapState(ring,t)
%16 态映射（与源码 state_mapping 一致）：3 个符号（1 在前）× t∈{5,2}
pos=(ring(1)<0)*4+(ring(2)<0)*2+(ring(3)<0)*1;
s=pos*2+(t==2);
end

function [A,B,Dl]=updLeaders(A,B,Dl,x,v,literalAuthor)
%paper 模式：标准三优跟踪；author 模式：源码字面顺序（含其怪异性）
if ~literalAuthor
    if v<A.Cost
        Dl=B; B=A; A=struct('Cost',v,'Vector',x);
    elseif v<B.Cost
        Dl=B; B=struct('Cost',v,'Vector',x);
    elseif v<Dl.Cost
        Dl=struct('Cost',v,'Vector',x);
    end
    return;
end
if v<A.Cost
    Dl=B; B=A; A=struct('Cost',v,'Vector',x);
end
if v>A.Cost && v<B.Cost
    Dl=B; B=struct('Cost',v,'Vector',x);
end
if v>A.Cost && v>B.Cost && v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end

function [A,B,Dl,reward,next_state,fe,T,gb,bVec]=leaderAction(action,aGlobal,f,A,B,Dl,lb,ub,fe,budget,T,D,gb,bVec)
%作者 updateLeaderByAction 的忠实移植（动作 0：Gamma 扰动；动作 1：指数扰动）
reward=-2; next_state=2;
if fe>=budget, return; end
if aGlobal<0.7, q=1; else, q=-1; end
if action==0
    r=gamrnd(1.5,0.4,1,D);
else
    r=exprnd(1,1,D);
end
xp=min(max(A.Vector-q*A.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; if v<gb, gb=v; bVec=xp; end; T(fe)=gb;
if A.Cost>v
    A=struct('Cost',v,'Vector',xp); reward=reward+30; next_state=0;
end
if fe>=budget, return; end
xp=min(max(B.Vector-B.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; if v<gb, gb=v; bVec=xp; end; T(fe)=gb;
if B.Cost>v
    B=struct('Cost',v,'Vector',xp); reward=reward+15;
    if next_state==2, next_state=1; end
end
if fe>=budget, return; end
xp=min(max(Dl.Vector-Dl.Vector.*r,lb),ub);
v=f(xp); fe=fe+1; if v<gb, gb=v; bVec=xp; end; T(fe)=gb;
if Dl.Cost>v
    Dl=struct('Cost',v,'Vector',xp); reward=reward+5;
    if next_state==2, next_state=1; end
end
end
