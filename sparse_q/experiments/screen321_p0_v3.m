function out=screen321_p0_v3(seeds,maxFE,D,funcs,tag)
%SCREEN321_P0_V3  P0 for the no-pool structure with a fixed 4/3/3 evaluation quota.
%   A0 Full       G1 4 + DiffA 3 + E 3
%   A1 Base       G1 10
%   A2 E-only     G1 7 + E 3
%   A3 Diff-only  G1 7 + DiffA 3
%   29 functions x 6 seeds, D=50, 100k FE, M=K=10.
if nargin<1 || isempty(seeds), seeds=4901:4906; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_v3'; end
arms={'full','base','eonly','diffonly'};
labels={'A0-Full','A1-Base','A2-Eonly','A3-Diffonly'};
st=cell(1,4);
for k=1:4, st{k}=struct('ablationVariant',arms{k}); end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_AB'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
