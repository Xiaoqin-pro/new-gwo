function out=screen95_pair_p0(seeds,maxFE,D,funcs,tag)
%SCREEN95_PAIR_P0  Passive P0-Value audit of quality-aware elite pairing (docs/88).
if nargin<1 || isempty(seeds), seeds=3614:3618; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='pair_p0'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'pairMode','audit');
opt=struct(); opt.states={st}; opt.labels={'PAIR-Audit'};
out=run_batch_sq(tag,{'SGWO_PAIR'},funcs(:),seeds(:),D,maxFE,opt);
end
