function out=screen66_stj_confirm(seeds,maxFE,D,funcs,tag)
%SCREEN66_STJ_CONFIRM  Single new arm (STJ); A2 and always-on STEER are reused.
if nargin<1 || isempty(seeds), seeds=3071:3100; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='stj_confirm'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','stj','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'stjTauFrac',0.02,'stjTauMin',500);
opt=struct(); opt.states={st}; opt.labels={'C-STJ'};
out=run_batch_sq(tag,{'SGWO_STEER'},funcs,seeds,D,maxFE,opt);
end
