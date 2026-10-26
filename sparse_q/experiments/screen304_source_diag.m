function out=screen304_source_diag(seeds,maxFE,D,funcs,tag)
%SCREEN304_SOURCE_DIAG  Short diagnostic run to measure per-source contribution.
%   Only the FULL arm, few functions and seeds; produces ImpCnt/EvalBySource so we
%   can see how many accepted improvements actually come from DiffA (G2) and E.
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 9 10 13 14 18 19 20 22 30]; end
if nargin<5 || isempty(tag), tag='source_diag'; end
opt=struct('states',{{struct()}},'labels',{{'A-Full'}});
out=run_batch_sq(tag,{'SVADGWO2'},funcs(:),seeds(:),D,maxFE,opt);
end
