function out=screen314b_p0_stratgeo(seeds,maxFE,D,funcs,tag)
%SCREEN314B  P0 for per-source geometric screening: 29 functions x 6 seeds, 3 arms.
if nargin<1 || isempty(seeds), seeds=4841:4846; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_stratgeo_c'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'defer',0);
st=cell(1,3);
st{1}=b; st{1}.screening='rand';
st{2}=b; st{2}.screening='stratgeo';
st{3}=b; st{3}.screening='stratcore';
labels={'R0-rand','R1-stratgeo','R2-stratcore'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,3),funcs(:),seeds(:),D,maxFE,opt);
end
