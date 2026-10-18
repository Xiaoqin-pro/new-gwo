function [Best,T,info]=CLPSO_CEC(f,state,~,N,seed)
%CLPSO_CEC  CLPSO 严格复现（Liang, Qin, Suganthan & Baskar, IEEE TEC 2006）
%  参考实现：TEC2006 原版代码包 CLPSO_new_func.m（镜像：
%  NTU-CCA/EE6227@Reference/.../TEC matlab code/CLPSO_new_func.m）。
%  逐机制对应（与原始代码一致）：
%    * Pc_i = 0.5*(exp(5*(i-1)/(ps-1))-1)/(exp(5)-1)，范围 [0,0.5]
%    * cc=[1.49445 1.49445]；m(k)=0（原版包中 ai 恒为 0，纯 pbest 示范学习）
%    * 逐维示范粒子 fi=fi1/ fi2 取 pbest 更优者（并列取 fi2）；bi=1 概率 Pc_i；
%      若某粒子全部维度都未命中，随机强制一维为 1
%    * **示范索引 f_pbest 跨代保持**，仅在 stay_num(k)>=5（刷新间隔 5）时重抽
%    * w 线性 0.9->0.2；速度限幅 mv=0.2*(ub-lb)；越界位置**不评价、不回拉**
%    * pbestval<=e 记一次未改善（stay_num+1）
%  与实验框架的适配（仅接口/计费，逐条记录于 docs/16）：
%    * 位置初始种群由框架给定（同池）；速度仍按原版 U(-mv,mv) 初始化
%    * 原版按代数 + fitcount 双条件、且逐粒子循环内不检查预算（最多超支 ps-1 次）；
%      本实现逐次评价检查预算，真实 FE 精确等于预算
%    * w 调度以真实 FE 进度计：w=0.9-0.7*(fe/budget)（原版按代数 i/Max_Gen 线性）
%    * 种群规模按原论文设置 N=40（框架 algorithmPopulation('CLPSO')=40）
D=size(state.initialPopulation,2);
N0=size(state.initialPopulation,1); assert(N0==N);
lb=state.lowerBound; ub=state.upperBound; budget=state.maxEvaluations;
rng(seed,'twister');
T=nan(budget,1);
pos=state.initialPopulation;
mv=0.2*(ub-lb);
Vmin=-mv; Vmax=mv;
vel=Vmin+2.*Vmax.*rand(N,D);
ps=N;
t=0:1/(ps-1):1; t=5.*t;
Pc=0.5.*(exp(t)-exp(t(1)))./(exp(t(ps))-exp(t(1)));
cc1=1.49445; cc2=1.49445;
mvec=zeros(ps,1);                 % 原版包 m=0：ai 恒为 0
ai=zeros(ps,D);
f_pbest=repmat((1:ps)',1,D);
fe=0; gb=inf; bVec=pos(1,:);
e=inf(ps,1);
for k=1:ps
    v=f(pos(k,:)); fe=fe+1;
    e(k)=v;
    if v<gb, gb=v; bVec=pos(k,:); end
    T(fe)=gb;
end
pbest=pos; pbestval=e;
[gbestval,gbestid]=min(pbestval); gbest=pbest(gbestid,:);
stay_num=zeros(ps,1);
for k=1:ps
    ar=randperm(D); ai(k,ar(1:mvec(k)))=1;
    fi1=ceil(ps*rand(1,D)); fi2=ceil(ps*rand(1,D));
    cmp=(pbestval(fi1)<pbestval(fi2))';   % pbestval 为列向量，索引结果为列 → 转置为 1×D
    fi=cmp.*fi1+(1-cmp).*fi2;
    bi=double(rand(1,D)<Pc(k));   % ceil(rand-1+Pc) 等价形式
    if all(bi==0), rc=randperm(D); bi(rc(1))=1; end
    f_pbest(k,:)=bi.*fi+(1-bi).*f_pbest(k,:);
end
while fe<budget
    w=0.9-0.7*(fe/budget);
    gbestrep=repmat(gbest,ps,1);
    for k=1:ps
        if fe>=budget, break; end
        if stay_num(k)>=5
            stay_num(k)=0;
            ai(k,:)=zeros(1,D);
            f_pbest(k,:)=k.*ones(1,D);
            ar=randperm(D); ai(k,ar(1:mvec(k)))=1;
            fi1=ceil(ps*rand(1,D)); fi2=ceil(ps*rand(1,D));
            cmp=(pbestval(fi1)<pbestval(fi2))';   % pbestval 为列向量，索引结果为列 → 转置为 1×D
    fi=cmp.*fi1+(1-cmp).*fi2;
            bi=double(rand(1,D)<Pc(k));
            if all(bi==0), rc=randperm(D); bi(rc(1))=1; end
            f_pbest(k,:)=bi.*fi+(1-bi).*f_pbest(k,:);
        end
        pbf=zeros(1,D);
        for dc=1:D, pbf(dc)=pbest(f_pbest(k,dc),dc); end
        aa=cc1.*(1-ai(k,:)).*rand(1,D).*(pbf-pos(k,:)) + ...
           cc2.*ai(k,:).*rand(1,D).*(gbestrep(k,:)-pos(k,:));
        vel(k,:)=w.*vel(k,:)+aa;
        vel(k,:)=min(max(vel(k,:),Vmin),Vmax);
        pos(k,:)=pos(k,:)+vel(k,:);
        if (sum(pos(k,:)>ub)+sum(pos(k,:)<lb))==0
            v=f(pos(k,:)); fe=fe+1;
            if v<gb, gb=v; bVec=pos(k,:); end
            T(fe)=gb;
            tmp=(pbestval(k)<=v);
            if tmp, stay_num(k)=stay_num(k)+1; end
            pbest(k,:)=tmp.*pbest(k,:)+(1-tmp).*pos(k,:);
            pbestval(k)=tmp.*pbestval(k)+(1-tmp).*v;
            if pbestval(k)<gbestval
                gbest=pbest(k,:); gbestval=pbestval(k);
            end
        end
    end
end
Best=struct('Cost',gb,'Vector',bVec);
info=struct('Evaluations',fe,'Algorithm','CLPSO-CEC','Rounds',NaN);
end
