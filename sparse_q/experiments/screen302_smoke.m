function out=screen302_smoke()
% Quick smoke: 3 functions x 1 fresh seed for the four v2 arms + the entry point.
if nargin<1, end
seeds=4631; funcs=[1 4 13]; maxFE=30000; D=50;
arms={'full','base','eonly','diffonly'};
labels={'A-Full','B-Base','C-Eonly','D-Diffonly'};
st=cell(1,numel(arms));
for k=1:numel(arms), st{k}=struct('ablationVariant',arms{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq('v2_smoke',repmat({'SVADGWO2_AB'},1,4),funcs,seeds,D,maxFE,opt);
end
