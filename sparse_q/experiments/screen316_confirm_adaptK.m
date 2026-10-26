function out=screen316_confirm_adaptK(seeds,maxFE,D,funcs,tag)
%SCREEN316_CONFIRM_ADAPTK  Confirmation of stall-driven adaptive K on fresh seeds.
%   U0 fixed K=10
%   U1 adaptK 4..20, stallTol 2000   (P0 winner)
%   U2 adaptK 4..20, stallTol 3000
%   U3 adaptK 6..20, stallTol 2000
if nargin<1 || isempty(seeds), seeds=4861:4866; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='confirm_adaptK'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'screening','rand');
st=cell(1,4);
st{1}=b;
st{2}=b; st{2}.adaptK=1; st{2}.Kmin=4; st{2}.Kmax=20; st{2}.stallTol=2000;
st{3}=b; st{3}.adaptK=1; st{3}.Kmin=4; st{3}.Kmax=20; st{3}.stallTol=3000;
st{4}=b; st{4}.adaptK=1; st{4}.Kmin=6; st{4}.Kmax=20; st{4}.stallTol=2000;
labels={'U0-K10','U1-4/20-2000','U2-4/20-3000','U3-6/20-2000'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
