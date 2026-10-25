function out=screen294_svadgwo_ablation30(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svadgwo_ablation30'; end
algs=repmat({'SVADGWO_AB'},1,5);
labels={'A-SVADGWO','B-NoDiff','C-NoE','D-NoSteer','E-GWOonly'};
v={'full','nodiff','noe','nosteer','gwo'};
st=cell(1,5);
for k=1:5, st{k}=struct('ablationVariant',v{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
