% SUPERSEDED by screen17_final_audit.m — never executed (recorded in docs/12 Addendum B).
function out=screen16_d50audit(seeds,maxFE,D)
%SCREEN16  D50 尺度的方向审计（docs/12 Addendum A，预注册）：
%   A-g1（仅 G1 真实成功位移）/ A-rand（等长随机方向对照）。
%   mix（V2-steer50）与 ref（V1）复用 freshv2 同种子结果，不重跑。
if nargin<1 || isempty(seeds), seeds=3031:3040; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
g1=base;  g1.succSteer=0.5; g1.sdirSource='g1';
rnd=base; rnd.succSteer=0.5; rnd.sdirSource='random';
algs={'SGWO','SGWO'};
labels={'A-g1','A-rand'};
states=cell(1,2); states{1}=g1; states{2}=rnd;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('aud50',algs,funcs,seeds,D,maxFE,opt);
end

