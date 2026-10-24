function out=screen269_diffslot_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4329:4338; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 5 6 7 8 9 10 11 13 14 18 20 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffslot_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                                  % A: 冻结（shell G2 + E）
b=base; b.g2Mode='diff'; b.g2Pool='pool';    % B: 差分槽位，池=狼群+E档案
c=base; c.g2Mode='diff'; c.g2Pool='wolves';  % C: 差分槽位，池=仅狼群
d=base; d.g2Mode='diff'; d.g2Pool='pool'; d.g2F=1.0;  % D: 差分槽位 F=1，池=pool
algs=repmat({'SGWO_STEER3'},1,4);
labels={'A-ShellG2','B-DiffSlot-Pool','C-DiffSlot-Wolves','D-DiffSlot-F10'};
opt=struct('states',{ {a,b,c,d} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
