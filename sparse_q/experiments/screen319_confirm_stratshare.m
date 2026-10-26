function out=screen319_confirm_stratshare(seeds,maxFE,D,funcs,tag)
%SCREEN319_CONFIRM  Independent confirmation of the 4/2/4 quota + adaptive K.
%   X0 uniform random, fixed slots, fixed K   (baseline)
%   X1 quota 4/2/4 + adaptive K               (P0 winner)
%   X2 quota 4/2/4, fixed K                   (isolates the quota)
%   X3 quota 3/3/4 + adaptive K               (quota control)
if nargin<1 || isempty(seeds), seeds=4891:4896; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='confirm_stratshare'; end
b=struct('adaptSlots',0,'nG2',12,'nE',38,'adaptK',0);
st=cell(1,4);
st{1}=b; st{1}.screening='rand';
st{2}=b; st{2}.screening='stratshare'; st{2}.qG1=0.4; st{2}.qG2=0.2; st{2}.adaptK=1; st{2}.Kmin=4; st{2}.Kmax=20; st{2}.stallTol=2000;
st{3}=b; st{3}.screening='stratshare'; st{3}.qG1=0.4; st{3}.qG2=0.2;
st{4}=b; st{4}.screening='stratshare'; st{4}.qG1=0.3; st{4}.qG2=0.3; st{4}.adaptK=1; st{4}.Kmin=4; st{4}.Kmax=20; st{4}.stallTol=2000;
labels={'X0-rand','X1-q424-K','X2-q424','X3-q334-K'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
