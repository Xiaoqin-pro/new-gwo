function out=screen320_p0_direct(seeds,maxFE,D,funcs,tag)
%SCREEN320_P0_DIRECT  No candidate pool: generate exactly the K evaluated candidates.
%   Y0  M=100, K=10, uniform random screening, 50/12/38 slots   (current design)
%   Y1  M=10,  K=10, direct generation, quota 4/3/3             (no pool, no screening)
%   Y2  M=10,  K=10, direct generation, quota 4/2/4
%   Y3  M=10,  K=10, direct generation, quota 5/3/2
%   Y4  M=20,  K=10, quota 4/3/3 generation + random pick       (pool of 2K)
if nargin<1 || isempty(seeds), seeds=4901:4906; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_direct'; end
st=cell(1,5);
st{1}=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','rand','adaptK',0,'M',100,'K',10);
st{2}=struct('adaptSlots',0,'nG2',3,'nE',3,'screening','rand','adaptK',0,'M',10,'K',10);
st{3}=struct('adaptSlots',0,'nG2',2,'nE',4,'screening','rand','adaptK',0,'M',10,'K',10);
st{4}=struct('adaptSlots',0,'nG2',3,'nE',2,'screening','rand','adaptK',0,'M',10,'K',10);
st{5}=struct('adaptSlots',0,'nG2',6,'nE',8,'screening','rand','adaptK',0,'M',20,'K',10);
labels={'Y0-M100-K10','Y1-M10-433','Y2-M10-424','Y3-M10-532','Y4-M20-433'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
