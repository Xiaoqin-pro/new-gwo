function out=screen318_p0_stratshare(seeds,maxFE,D,funcs,tag)
%SCREEN318_P0_STRATSHARE  Fixed evaluation quota per source: 29 fn x 6 seeds.
%   W0  uniform random, fixed 50/12/38 slots        (old design)
%   W1  quota 4/3/3,  fixed slots
%   W2  quota 4/3/3,  + adaptive K
%   W3  quota 5/3/2,  + adaptive K
%   W4  quota 4/2/4,  + adaptive K
if nargin<1 || isempty(seeds), seeds=4881:4886; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_stratshare'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'adaptK',0);
st=cell(1,5);
st{1}=b; st{1}.screening='rand';
st{2}=b; st{2}.screening='stratshare'; st{2}.qG1=0.4; st{2}.qG2=0.3;
st{3}=b; st{3}.screening='stratshare'; st{3}.qG1=0.4; st{3}.qG2=0.3; st{3}.adaptK=1; st{3}.Kmin=4; st{3}.Kmax=20; st{3}.stallTol=2000;
st{4}=b; st{4}.screening='stratshare'; st{4}.qG1=0.5; st{4}.qG2=0.3; st{4}.adaptK=1; st{4}.Kmin=4; st{4}.Kmax=20; st{4}.stallTol=2000;
st{5}=b; st{5}.screening='stratshare'; st{5}.qG1=0.4; st{5}.qG2=0.2; st{5}.adaptK=1; st{5}.Kmin=4; st{5}.Kmax=20; st{5}.stallTol=2000;
labels={'W0-rand','W1-q433','W2-q433-K','W3-q532-K','W4-q424-K'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
