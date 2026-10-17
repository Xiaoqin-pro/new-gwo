function out=screen18_ablation_core(seeds,maxFE,D,withA5)
%SCREEN18  V1 候选来源消融（docs/13_ABLATION.md 预注册）：
%   A0=GWO-only sparse（G2/E 槽位由标准 GWO 候选填补；M=100 不变）
%   A1=G1+G2（E 槽位填补） / A2=G1+E（G2 槽位填补） / A3=完整 V1（须与冻结 SGWO 逐位一致）
%   A5=档案多中心 -> Alpha 单中心替代（其余不变，隔离"多区域空间信息"）
%   等 M=100、K=10、100k 真 FE、同初始池；唯一变量 = 候选来源组成。
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(withA5), withA5=true; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
a0=base; a0.ablateG2=1; a0.ablateE=1;
a1=base; a1.ablateE=1;
a2=base; a2.ablateG2=1;
a3=base;
a5=base; a5.alphaSingleE=1;
algs={'SGWOAB','SGWOAB','SGWOAB','SGWOAB'};
labels={'A0-GWOonly','A1-G1G2','A2-G1E','A3-V1full'};
states=cell(1,4); states{1}=a0; states{2}=a1; states{3}=a2; states{4}=a3;
if withA5
    algs{5}='SGWOAB'; labels{5}='A5-NoArchive'; states{5}=a5;
end
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('ablcore',algs,funcs,seeds,D,maxFE,opt);
end
