function out=screen274_diffa_slot_p1b(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4369:4378; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_slot_p1b'; end
a=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
b=a; b.g2Mode='diffa'; b.g2Pool='pool'; b.g2F=1.0;
c=a; c.g2Mode='diffa'; c.g2Pool='pool'; c.g2F=0.5;
algs=repmat({'SGWO_STEER3'},1,3);
labels={'A-Frozen','B-DiffASlot-F10','C-DiffASlot-F05'};
opt=struct('states',{ {a,b,c} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
