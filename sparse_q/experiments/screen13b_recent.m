function out=screen13b_recent(seeds,maxFE,D,v2mode,v2label)
%SCREEN13B  screen13 的 25 种子扩展（3006:3030），合并后为 30 种子对比表。
if nargin<1 || isempty(seeds), seeds=3006:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(v2mode), v2mode='steer50'; end
if nargin<5 || isempty(v2label), v2label='V2-steer50'; end
funcs=[1 3:30];
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
switch v2mode
    case 'combo'
        v2=base; v2.succSteer=0.5; v2.g2Subset=0.2;
    otherwise
        v2=base; v2.succSteer=0.5;
end
algs={'SGWO','DMSGWO','RLGWO','IGWO','GWO'};
labels={v2label,'DMSGWO-port','RLGWO-port','IGWO','GWO'};
states=cell(1,5); states{1}=v2;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('recent2',algs,funcs,seeds,D,maxFE,opt);
end
