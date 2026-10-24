function out=screen270_diffslot_p1(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4339:4348; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffslot_p1'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;
b=base; b.g2Mode='diff'; b.g2Pool='pool';
c=base; c.g2Mode='diff'; c.g2Pool='wolves';
algs=repmat({'SGWO_STEER3'},1,3);
labels={'A-ShellG2','B-DiffSlot-Pool','C-DiffSlot-Wolves'};
opt=struct('states',{ {a,b,c} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
