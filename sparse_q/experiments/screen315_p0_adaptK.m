function out=screen315_p0_adaptK(seeds,maxFE,D,funcs,tag)
%SCREEN315_P0_ADAPTK  P0: adaptive evaluation frequency. 29 functions x 6 seeds.
%   T0  fixed K=10 (baseline)
%   T1  adaptive K, 4..20, stallTol=2000
%   T2  adaptive K, 4..35, stallTol=2000
%   T3  adaptive K, 5..15, stallTol=1000
%   T4  adaptive K, 4..25, stallTol=5000
if nargin<1 || isempty(seeds), seeds=4851:4856; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_adaptK'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','rand');
st=cell(1,5);
st{1}=b;
st{2}=b; st{2}.adaptK=1; st{2}.Kmin=4;  st{2}.Kmax=20; st{2}.stallTol=2000;
st{3}=b; st{3}.adaptK=1; st{3}.Kmin=4;  st{3}.Kmax=35; st{3}.stallTol=2000;
st{4}=b; st{4}.adaptK=1; st{4}.Kmin=5;  st{4}.Kmax=15; st{4}.stallTol=1000;
st{5}=b; st{5}.adaptK=1; st{5}.Kmin=4;  st{5}.Kmax=25; st{5}.stallTol=5000;
labels={'T0-K10','T1-4/20-2000','T2-4/35-2000','T3-5/15-1000','T4-4/25-5000'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
