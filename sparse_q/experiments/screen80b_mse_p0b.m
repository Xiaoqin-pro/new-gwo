function out=screen80b_mse_p0b(seeds,maxFE,D,funcs,tag)
%SCREEN80B_MSE_P0B  MSE P0b (corrected, intent-faithful clipping metrics) on fresh seeds.  docs/74.
if nargin<1 || isempty(seeds), seeds=3504:3508; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='mse_p0b'; end
st=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5,'mseMode','audit','mseSeedOffset',777777);
opt=struct(); opt.states={st}; opt.labels={'MSE-AuditB'};
out=run_batch_sq(tag,{'SGWO_MSE'},funcs(:),seeds(:),D,maxFE,opt);
end
