function [Best,T,info]=AOGWO_CEC(f,state,~,N,seed)
%AOGWO_CEC  AOGWO 移植（Sci Rep 2026, s41598-026-53090-6；作者源码
%   OthmanWaleed/AOGWO @AOGWO_17.m，逐机制对应：混合反向学习初始化 /
%   余弦自适应 a / 衰减跳跃率 Jr + Levy / 仅对 Alpha 的选择性反向 SLO）。
%  与作者代码的差异（接口与计费；逐条记录于 docs/15）：
%    * 搜索域取实验框架 [-100,100]^D（作者演示码硬编码 [0,1]；反向学习公式本身
%      只依赖 lb/ub，属尺度适配，机制不变）
%    * 初始人口 = 框架共享基池 + 作者的 DO 混合反向初始化变换
%    * 调度变量：a=2cos(pi/2*prog)、Jr=0.5(1-prog)，prog=fe/budget（等 FE 适配；
%      作者用 t/maxIter）；逐次评价检查预算，绝不超支
%    * 同一位置不重复评价（作者每轮全群重评；本实现每轮位置必变，等价）
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
% ---- 1) Hybrid OBL 初始化（作者行 46-56；基池来自框架） ----
for i=1:N
    OP=((ub-lb).*rand(1,D))+lb-X(i,:);
    RO=rand*OP;
    DO=X(i,:)+rand*(RO-X(i,:));
    X(i,:)=min(max(DO,lb),ub);
end
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
fe=0; gb=inf; bVec=X(1,:);
while fe<budget
    prog=fe/budget;
    % ---- 评价全群（作者每轮重评；位置每轮必变） ----
    for i=1:N
        if fe>=budget, break; end
        v=f(X(i,:)); fe=fe+1;
        if v<gb, gb=v; bVec=X(i,:); end
        T(fe)=gb;
        [Alpha,Beta,Delta]=cascade(Alpha,Beta,Delta,X(i,:),v);
    end
    if fe>=budget, break; end
    % ---- 2) 余弦自适应 + 跳跃率 ----
    a=2*cos((pi/2)*prog);
    Jr=0.5*(1-prog);
    % ---- 3) 位置更新 ----
    for i=1:N
        if rand<Jr
            X(i,:)=Alpha.Vector-a*abs(rand*Alpha.Vector-X(i,:))+rand(1,D).*levyVec(D);
        else
            for j=1:D
                r1=rand(); r2=rand(); A1=2*a*r1-a; C1=2*r2;
                X1=Alpha.Vector(j)-A1*abs(C1*Alpha.Vector(j)-X(i,j));
                r1=rand(); r2=rand(); A2=2*a*r1-a; C2=2*r2;
                X2=Beta.Vector(j)-A2*abs(C2*Beta.Vector(j)-X(i,j));
                r1=rand(); r2=rand(); A3=2*a*r1-a; C3=2*r2;
                X3=Delta.Vector(j)-A3*abs(C3*Delta.Vector(j)-X(i,j));
                X(i,j)=(X1+X2+X3)/3;
            end
        end
        X(i,:)=min(max(X(i,:),lb),ub);
    end
    % ---- 4) SLO：仅对 Alpha 的选择性反向 ----
    if fe<budget && rand<0.5
        cmin=min(X,[],1); cmax=max(X,[],1);
        Opp=min(max(cmin+cmax-Alpha.Vector,lb),ub);
        v=f(Opp); fe=fe+1;
        if v<gb, gb=v; bVec=Opp; end
        T(fe)=gb;
        if v<Alpha.Cost, Alpha=struct('Cost',v,'Vector',Opp); end
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','AOGWO-CEC','Rounds',floor(fe/N));
end

function [A,B,Dl]=cascade(A,B,Dl,x,v)
%作者源码的严格级联（严格 < ）
if v<A.Cost
    A=struct('Cost',v,'Vector',x);
elseif v<B.Cost
    B=struct('Cost',v,'Vector',x);
elseif v<Dl.Cost
    Dl=struct('Cost',v,'Vector',x);
end
end

function L=levyVec(D)
beta=1.5;
sigma=(gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
u=randn(1,D)*sigma; v=randn(1,D);
L=0.01*(u./abs(v).^(1/beta));   % 作者 Levy() 内含 0.01 因子
end
