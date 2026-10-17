function out=screen17_final_audit(seeds,maxFE,D)
%SCREEN17  最终方向归因轮（docs/12 Addendum B，预注册；四臂单批，全新种子 3061:3070）：
%   V1-ref / V2-steer50(mix) / V2-G1(仅G1成功位移) / V2-Random(等长随机方向对照)。
%   唯一变量 = 方向向量来源；其余选项逐项一致（succSteer=0.5 固定）。
if nargin<1 || isempty(seeds), seeds=3061:3070; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
mix=base; mix.succSteer=0.5;
g1=mix;  g1.sdirSource='g1';
rnd=mix; rnd.sdirSource='random';
algs=repmat({'SGWO'},1,4);
labels={'V1-ref','V2-steer50','V2-G1','V2-Random'};
states=cell(1,4); states{1}=base; states{2}=mix; states{3}=g1; states{4}=rnd;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('finalaud',algs,funcs,seeds,D,maxFE,opt);
end
