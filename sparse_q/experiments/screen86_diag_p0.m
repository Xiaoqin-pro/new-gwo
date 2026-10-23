function out=screen86_diag_p0(seeds,maxFE,D,funcs,tag)
%SCREEN86_DIAG_P0  Passive allocation-structure diagnosis (docs/79).
if nargin<1 || isempty(seeds), seeds=3569:3573; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='diag_p0'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
opt=struct(); opt.states={st}; opt.labels={'Diag'};
out=run_batch_sq(tag,{'SGWO_DIAG'},funcs(:),seeds(:),D,maxFE,opt);
end
