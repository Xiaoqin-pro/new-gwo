function out=screen317_p0_combined(seeds,maxFE,D,funcs,tag)
%SCREEN317_P0_COMBINED  Adaptive frequency x adaptive slots: 29 fn x 6 seeds.
%   V0  fixed K=10, fixed 50/12/38          (old hand-set design)
%   V1  adaptK only,  fixed 50/12/38        (P0/confirm winner so far)
%   V2  adaptK + adaptive slots             (both ratios and frequency emerge)
%   V3  adaptK + adaptive slots, beta=1     (gentler slot adaptation)
%   V4  adaptK + adaptive slots, beta=4     (sharper slot adaptation)
if nargin<1 || isempty(seeds), seeds=4871:4876; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_combined'; end
b=struct('screening','rand');
st=cell(1,5);
st{1}=b; st{1}.adaptK=0; st{1}.adaptSlots=0; st{1}.nG2=12; st{1}.nE=38;
st{2}=b; st{2}.adaptK=1; st{2}.Kmin=4; st{2}.Kmax=20; st{2}.stallTol=2000; st{2}.adaptSlots=0; st{2}.nG2=12; st{2}.nE=38;
st{3}=b; st{3}.adaptK=1; st{3}.Kmin=4; st{3}.Kmax=20; st{3}.stallTol=2000; st{3}.adaptSlots=1; st{3}.allocBeta=2.0;
st{4}=b; st{4}.adaptK=1; st{4}.Kmin=4; st{4}.Kmax=20; st{4}.stallTol=2000; st{4}.adaptSlots=1; st{4}.allocBeta=1.0;
st{5}=b; st{5}.adaptK=1; st{5}.Kmin=4; st{5}.Kmax=20; st{5}.stallTol=2000; st{5}.adaptSlots=1; st{5}.allocBeta=4.0;
labels={'V0-fixed-both','V1-adaptK-only','V2-both-b2','V3-both-b1','V4-both-b4'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
