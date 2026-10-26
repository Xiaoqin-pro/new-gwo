function out=screen303_v2_main_3001(seeds,maxFE,D,funcs,tag)
%SCREEN303_V2_MAIN_3001  SVAD-GWO v2 (STEER removed) on the main-table seeds.
%   Only our own algorithm; the eight external baselines are unchanged and are
%   reused from fourarm_3001, so the nine-arm table simply swaps its SVAD row.
if nargin<1 || isempty(seeds), seeds=3001:3030; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='svadgwo2_main3001'; end
opt=struct('states',{{struct()}},'labels',{{'SVAD-GWO (v2)'}});
out=run_batch_sq(tag,{'SVADGWO2'},funcs(:),seeds(:),D,maxFE,opt);
end
