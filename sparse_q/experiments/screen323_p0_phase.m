function out=screen323_p0_phase(seeds,maxFE,D,funcs,tag)
%SCREEN323_P0_PHASE  Phase-switched inner-source screening: 29 fn x 6 seeds.
%   P0  M=20 quota 4/3/3 uniform random within source   (baseline)
%   P1  inner (fixed 50/50 refine/cover)                (previous best)
%   P2  innerph stall=1000, wNear 0.75/0.25             (phase switched)
%   P3  innerph stall=500,  wNear 0.85/0.15             (quicker switch)
%   P4  innerph stall=2000, wNear 0.65/0.35             (slower switch)
if nargin<1 || isempty(seeds), seeds=4921:4926; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_phase'; end
b=struct('M',20,'K',10,'nG2',3,'nE',3,'adaptSlots',0,'adaptK',0,'useE',1,'useDiff',1);
st=cell(1,5);
st{1}=b; st{1}.screening='rand';
st{2}=b; st{2}.screening='inner';
st{3}=b; st{3}.screening='innerph'; st{3}.phStall=1000; st{3}.wNearMove=0.75; st{3}.wNearStag=0.25;
st{4}=b; st{4}.screening='innerph'; st{4}.phStall=500;  st{4}.wNearMove=0.85; st{4}.wNearStag=0.15;
st{5}=b; st{5}.screening='innerph'; st{5}.phStall=2000; st{5}.wNearMove=0.65; st{5}.wNearStag=0.35;
labels={'P0-rand','P1-inner','P2-ph1000','P3-ph500','P4-ph2000'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
