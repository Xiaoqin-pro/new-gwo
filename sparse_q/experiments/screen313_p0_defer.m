function out=screen313_p0_defer(seeds,maxFE,D,funcs,tag)
%SCREEN313_P0_DEFER  P0: does deferred submission make selective screening work?
if nargin<1 || isempty(seeds), seeds=4831:4836; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_defer'; end
st=cell(1,6);
st{1}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','rand','defer',0);
st{2}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','rand','defer',1);
st{3}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','geo','defer',1);
st{4}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','arc','defer',1);
st{5}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','core','defer',1);
st{6}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','softpot','gammaA',0.5,'gammaR',0.5,'defer',1);
labels={'D0-nodef-rand','D1-defer-rand','D2-defer-geo','D3-defer-arc','D4-defer-maximin','D5-defer-soft'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,6),funcs(:),seeds(:),D,maxFE,opt);
end
