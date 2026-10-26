function out=screen314_p0_stratgeo(seeds,maxFE,D,funcs,tag)
%SCREEN314_P0_STRATGEO  P0: per-source screening (budgets preserved). 29 fn x 6 seeds.
%   R0  uniform random                       baseline
%   R1  stratgeo  (per-source: half near alpha, half maximin)
%   R2  stratcore (per-source maximin only)
%   R3  stratgeo + defer
%   R4  stratgeo with a 2/3-1/3 near/far split inside each source
if nargin<1 || isempty(seeds), seeds=4841:4846; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_stratgeo'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'defer',0);
st=cell(1,5);
st{1}=b; st{1}.screening='rand';
st{2}=b; st{2}.screening='stratgeo';
st{3}=b; st{3}.screening='stratcore';
st{4}=b; st{4}.screening='stratgeo'; st{4}.defer=1;
st{5}=b; st{5}.screening='stratgeo'; st{5}.kG1=4; st{5}.kG2s=2; st{5}.kEs=4;
labels={'R0-rand','R1-stratgeo','R2-stratcore','R3-sgeo+defer','R4-sgeo-424'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
