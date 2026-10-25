function out=screen279_diffa_fdecay_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4394:4403; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_fdecay_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结
b=base; b.g2Mode='diffa'; b.g2F=1.0; b.g2Anchor='any';      % B: 冠军 (F=1.0 any)
c=base; c.g2Mode='diffa'; c.g2F=1.0; c.g2Fend=0.3; c.g2Anchor='any'; % C: F 1.0->0.3 any
d=base; d.g2Mode='diffa'; d.g2F=1.0; d.g2Fend=0.3; d.g2Anchor='best';% D: F 1.0->0.3 best
e=base; e.g2Mode='diffa'; e.g2F=0.75; e.g2Fend=0.3; e.g2Anchor='any'; % E: F 0.75->0.3 any
f=base; f.g2Mode='diffa'; f.g2F=0.75; f.g2Fend=0.3; f.g2Anchor='best';% F: F 0.75->0.3 best
algs=repmat({'SGWO_STEER3'},1,6);
labels={'A-Frozen','B-F10Any','C-F1003Any','D-F1003Best','E-F07503Any','F-F07503Best'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
