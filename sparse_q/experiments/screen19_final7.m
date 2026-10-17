function out=screen19_final7(seeds,maxFE,D)
%SCREEN19  最终七算法主表的“新增臂”批（复用 seeds 3001:3030 既有结果：
%  SPSO-2011 / CLPSO / GWO / IGWO / VAST-GWO(V1)；本批只跑三个新臂）：
%    RL-LGWO(author)（敏感性对照）/ RL-LGWO(paper)（主表预注册）/ DMSGWO(recon)
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
funcs=[1 3:30];
sa=struct('rlMode','author'); sp=struct('rlMode','paper');
algs={'RLGWO','RLGWO','DMSGWO'};
labels={'RL-LGWO(author)','RL-LGWO(paper)','DMSGWO(recon)'};
states=cell(1,3); states{1}=sa; states{2}=sp; states{3}=struct();
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq('final7',algs,funcs,seeds,D,maxFE,opt);
end
