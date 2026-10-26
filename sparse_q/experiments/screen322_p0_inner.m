function out=screen322_p0_inner(seeds,maxFE,D,funcs,tag)
%SCREEN322_P0_INNER  Quota-fixed inner-source screening: 29 fn x 6 seeds.
%   I0  M=20, quota 4/3/3, uniform random within source   (baseline)
%   I1  M=20, quota 4/3/3, inner geometric screening      (our proposal)
%   I2  M=40, quota 4/3/3, inner geometric screening      (bigger pool)
%   I3  M=20, quota 4/3/3, inner maximin only
%   I4  M=100,quota 4/3/3, inner geometric screening      (old pool size)
if nargin<1 || isempty(seeds), seeds=4911:4916; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_inner'; end
b=struct('K',10,'nG2',3,'nE',3,'adaptSlots',0,'adaptK',0,'useE',1,'useDiff',1);
st=cell(1,5);
st{1}=b; st{1}.M=20;  st{1}.screening='rand';
st{2}=b; st{2}.M=20;  st{2}.screening='inner';
st{3}=b; st{3}.M=40;  st{3}.screening='inner';
st{4}=b; st{4}.M=20;  st{4}.screening='stratcore';
st{5}=b; st{5}.M=100; st{5}.screening='inner';
labels={'I0-M20-rand','I1-M20-inner','I2-M40-inner','I3-M20-maximin','I4-M100-inner'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
