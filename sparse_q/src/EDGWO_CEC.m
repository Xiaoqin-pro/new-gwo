function [Best,T,info]=EDGWO_CEC(f,state,~,N,seed)
%EDGWO_CEC  EDGWO 移植（Zhang & Chen, SWEVO 2025, doi:10.1016/j.swevo.2024.101795；
%   参考公开实现 TWCkaijin/Elite-driven-Grey-Wolf-Optimization @optimizers/EDGWO.py）。
%   标注：**第三方公开代码复现（非作者代码）**；机制与原文描述核对：
%   精英层（α/β/δ）与普通层的差异化更新；领导者搜索采用"按 A 动态切换"的
%   全局探索/局部利用算子；普通狼按概率 p=0.5(1-t/T) 在领导聚合与螺旋式
%   全局算子里二选一。
%  与参考实现的差异（接口与计费；逐条记录于 docs/15）：
%    * 初始种群由实验框架给定（同池）；原码为均匀随机
%    * 连续搜索域 [-100,100]^D；去除参考码中离散/特征选择专属分支
%    * max_iter = floor(budget/N)（每代 N 次真实评价）→ FE 精确等于预算
X=state.initialPopulation;
[N0,D]=size(X);
assert(N0==N,'Population size mismatch');
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
assert(numel(lb)==D && numel(ub)==D && budget>=N);
rng(seed,'twister');
T=nan(budget,1);
X=min(max(X,lb),ub);
Alpha=struct('Cost',inf,'Vector',zeros(1,D)); Beta=Alpha; Delta=Alpha;
fe=0; gb=inf; bVec=X(1,:);
maxIter=floor(budget/N);
for t=1:maxIter
    mean_pos=mean(X,1);
    % ---- 评价全群 + 领导级联（作者 elif 链） ----
    for i=1:N
        v=f(X(i,:)); fe=fe+1;
        if v<gb, gb=v; bVec=X(i,:); end
        T(fe)=gb;
        if v<Alpha.Cost
            Delta=Beta; Beta=Alpha; Alpha=struct('Cost',v,'Vector',X(i,:));
        elseif v<Beta.Cost
            Delta=Beta; Beta=struct('Cost',v,'Vector',X(i,:));
        elseif v<Delta.Cost
            Delta=struct('Cost',v,'Vector',X(i,:));
        end
    end
    a=2-(t-1)*(2/maxIter);   % 作者 t 从 0 起（range(max_iter)），对齐调度
    % ---- 位置更新 ----
    for i=1:N
        X1=vecComp(a,X(i,:),mean_pos,Alpha.Vector,lb,ub);
        X2=vecComp(a,X(i,:),mean_pos,Beta.Vector,lb,ub);
        X3=vecComp(a,X(i,:),mean_pos,Delta.Vector,lb,ub);
        if isLeader(X(i,:),Alpha.Vector,Beta.Vector,Delta.Vector)
            X(i,:)=(X1+X2+X3)/3;
        else
            if rand()<(0.5*(1-(t-1)/maxIter))
                X(i,:)=(X1+X2+X3)/3;
            else
                r5=rand(); l=-1+2*r5;
                X(i,:)=Alpha.Vector+norm(Alpha.Vector-X(i,:))*exp(l)*cos(2*pi*l);
            end
        end
        X(i,:)=min(max(X(i,:),lb),ub);
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','EDGWO-CEC','Rounds',maxIter,'Mode','public-python-port');
end

function y=vecComp(a,xi,Xm,target,lb,ub)
r1=rand(); r2=rand(); A=2*a*r1-a; C=2*r2;
if A<1
    y=target-A*abs(C*target-xi);
else
    r3=rand(); r4=rand();
    y=target-Xm-r3*(lb+(ub-lb)*r4);
end
end

function tf=isLeader(x,A,B,Dlv)
tol=@(v) 1e-8+1e-5*abs(v);
tf=all(abs(x-A)<=tol(A)) || all(abs(x-B)<=tol(B)) || all(abs(x-Dlv)<=tol(Dlv));
end
