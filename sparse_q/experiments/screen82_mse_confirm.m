function out=screen82_mse_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN82_MSE_CONFIRM  MSE confirm-scale test (stage 3a): the frozen-final arm is REUSED from the
%   steer robustness batch (same seeds), so only the MSE arm is run.  docs/75_MSE_CONFIRM_PREREG.md
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='mse_confirm'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'mseMode','mix','mseSeedOffset',777777);
opt=struct(); opt.states={st}; opt.labels={'B-MSE-Mix'};
out=run_batch_sq(tag,{'SGWO_MSE'},funcs(:),seeds(:),D,maxFE,opt);
end
