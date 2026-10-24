function out=screen264_diffgwo_mix60_confirm30(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=3459:3488; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='diffgwo_mix60_confirm30'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',1,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','hybrid','opFixed',1,'opDiffMode','nowarc','opF',0.5,'opShare',0.6);
algs={'SGWO_STEER3'};
labels={'C-Mix60'};
opt=struct('states',{ {base} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
