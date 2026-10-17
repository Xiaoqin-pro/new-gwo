function out=final_20k(seeds,maxFE,D)
%FINAL_20K  资源受限协议（20k 真 FE，等预算）：GWO / B0 / B1 / S1-K50 / S*。
%   与 100k 的对比仅在标注清晰时作不等预算补充；主结论仍以 100k 为准。
if nargin<1 || isempty(seeds), seeds=3001:3010; end
if nargin<2 || isempty(maxFE), maxFE=20000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
base=struct('mode','sparse','K',50,'nG2',12,'nE',38);
sStar=base; sStar.K=10; sStar.screenPolicy='random';
s1=base; s1.screenPolicy='random';
b1=base; b1.mode='dense-sync';
algs={'GWO','ANGWO','SGWO','SGWO','SGWO'};
labels={'GWO','B0-ANGWO','B1-dense-sync','S1-pool38','S-star'};
states=cell(1,5);
states{2}=struct('exploreMode','fixed','exploreShare',0.20,'roverCenter','alpha','roverDest','random');
states{3}=b1; states{4}=s1; states{5}=sStar;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('f20k',algs,funcs,seeds,D,maxFE,opt);
end
