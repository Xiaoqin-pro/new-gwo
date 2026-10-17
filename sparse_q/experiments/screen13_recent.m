function out=screen13_recent(seeds,maxFE,D,v2mode)
%SCREEN13  近年强基线对比（5 种子快检；通过后由 screen13b 扩到 30 种子）：
%   V2-*（v2mode: 'steer50' | 'combo'）/ DMSGWO / RLGWO / IGWO / GWO。
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(v2mode), v2mode='steer50'; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
switch v2mode
    case 'combo'
        v2=base; v2.succSteer=0.5; v2.g2Subset=0.2; v2label='V2-combo';
    otherwise
        v2=base; v2.succSteer=0.5; v2label='V2-steer50';
end
algs={'SGWO','DMSGWO','RLGWO','IGWO','GWO'};
labels={v2label,'DMSGWO-port','RLGWO-port','IGWO','GWO'};
states=cell(1,5); states{1}=v2;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('recent',algs,funcs,seeds,D,maxFE,opt);
end
