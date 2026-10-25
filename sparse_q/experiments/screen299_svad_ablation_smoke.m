function out=screen299_svad_ablation_smoke(seeds,maxFE,D,funcs,tag)
%SCREEN299_SMOKE 消融烟测：2 函数 x 1 新种子（4631），确认 5 臂能跑且 FE 精确。
if nargin<1 || isempty(seeds), seeds=4631; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[4 13]; end
if nargin<5 || isempty(tag), tag='svad_ablation_smoke'; end
out=screen299_svad_ablation_factorial(seeds,maxFE,D,funcs,tag);
end
