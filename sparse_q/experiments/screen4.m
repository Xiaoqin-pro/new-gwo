function out=screen4(seeds,maxFE,D)
%SCREEN4  10 种子晋级复核：GWO / B0(ANGWO) / B1(dense-sync) / S1 / S* 骨架。
%   具体 S* 设置由调用前的 SCREEN2/3 结论决定（修改本文件的 states{5} 一次并记录）。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','SGWO','SGWO','SGWO'};
labels={'GWO','B0-ANGWO','B1-dense-sync','S1-pool38','Sstar'};
states=cell(1,5);
states{2}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
states{3}=struct('mode','dense-sync');
states{4}=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','random');
states{5}=struct('mode','sparse','K',50,'nG2',12,'nE',38,'screenPolicy','weighted','quotaPolicy','fixed','quotaFixed',0.25);
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('sq4',algs,funcs,seeds,D,maxFE,opt);
end
