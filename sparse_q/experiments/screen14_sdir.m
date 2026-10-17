function out=screen14_sdir(seeds,maxFE,D)
%SCREEN14  方向归因审计（docs/12_SDIR_AUDIT.md，预注册）：
%   steer50 的收益是否来自"已验证方向信息"，而非单纯额外扰动？
%   臂：S14-ref(V1) / S14-mix(现 steer50) / S14-g1(G1真实成功位移) /
%       S14-g2e(G2/E成功替换位移) / S14-rand(等长随机方向对照)。
%   除 sdirSource 外全部选项与 V2-steer50 相同（succSteer=0.5）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
mix=base; mix.succSteer=0.5;
g1=mix;  g1.sdirSource='g1';
g2e=mix; g2e.sdirSource='g2e';
rnd=mix; rnd.sdirSource='random';
algs=repmat({'SGWO'},1,5);
labels={'S14-ref','S14-mix','S14-g1','S14-g2e','S14-rand'};
states=cell(1,5); states{1}=base; states{2}=mix; states{3}=g1; states{4}=g2e; states{5}=rnd;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq14',algs,funcs,seeds,D,maxFE,opt);
end
