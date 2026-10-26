function out=screen302_v2_ablation(seeds,maxFE,D,funcs,tag)
%SCREEN302_V2_ABLATION  Final SVAD-GWO (v2, STEER removed) ablation, 4 arms.
%   Full + Base + E-only + Diff-only.  Single filler rule (plain GWO) everywhere;
%   no alpha-shell code is reachable from this structure.
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svadgwo2_ablation'; end
arms={'full','base','eonly','diffonly'};
labels={'A-Full','B-Base','C-Eonly','D-Diffonly'};
st=cell(1,numel(arms));
for k=1:numel(arms), st{k}=struct('ablationVariant',arms{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_AB'},1,numel(arms)),funcs(:),seeds(:),D,maxFE,opt);
end
