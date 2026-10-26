function out=screen308_p0_hybrid(seeds,maxFE,D,funcs,tag)
%SCREEN308_P0_HYBRID  P0 screen for hybrid screening rules: 29 functions x 6 seeds.
%   S0 rand                uniform random (baseline)
%   S3 core                source-guaranteed maximin (previous P0 winner among non-random)
%   S4 corehyb kLocal=5    half local (alpha-nearest), half maximin
%   S5 corephase 0.5       maximin for the first 50% of the budget, random after
%   S6 corephase 0.7       maximin for the first 70%, random after
if nargin<1 || isempty(seeds), seeds=4801:4806; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_hybrid'; end
st={ struct('screening','rand'), ...
     struct('screening','core'), ...
     struct('screening','corehyb','kLocal',5), ...
     struct('screening','corephase','phaseThresh',0.5), ...
     struct('screening','corephase','phaseThresh',0.7) };
labels={'S0-rand','S3-core','S4-hyb5','S5-phase05','S6-phase07'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,5),funcs(:),seeds(:),D,maxFE,opt);
end
