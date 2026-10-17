function out=screen15_steer_formal(arm,seeds,maxFE,D)
%SCREEN15  正式种子（3001:3030）单臂验证：SCREEN14 的 G14c 选出的 steer50 变体。
%   arm: 'mix'（现行两类方向混合）| 'g1'（仅 G1 真实成功位移）
%   与 17 基线主表（merged_runs.csv, seeds 3001:3030, D=50, 100k）同种子可比。
if nargin<1 || isempty(arm), arm='mix'; end
if nargin<2 || isempty(seeds), seeds=3001:3030; end
if nargin<3 || isempty(maxFE), maxFE=100000; end
if nargin<4 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
s=base; s.succSteer=0.5;
switch lower(arm)
    case 'g1'
        s.sdirSource='g1'; label='V2-steer50-g1';
    case 'mix'
        label='V2-steer50-fm';
    otherwise
        error('arm must be mix|g1');
end
algs={'SGWO'};
labels={label};
states=cell(1,1); states{1}=s;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('st50f',algs,funcs,seeds,D,maxFE,opt);
end
