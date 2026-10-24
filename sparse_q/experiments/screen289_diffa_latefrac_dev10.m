function out=screen289_diffa_latefrac_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4464:4473; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_latefrac_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结
b=base; b.g2Mode='diffa'; b.g2F=1.0; b.g2Pool='pool'; b.g2Anchor='any';               % B: 冠军 F=1.0
c=base; c.g2Mode='diffa'; c.g2F=1.0; c.g2Fend=0.5; c.g2FendFrac=0.7; c.g2Pool='pool'; c.g2Anchor='any'; % C: 后30% F->0.5
d=base; d.g2Mode='diffa'; d.g2F=1.0; d.g2Fend=0.5; d.g2FendFrac=0.5; d.g2Pool='pool'; d.g2Anchor='any'; % D: 后50% F->0.5
e=base; e.g2Mode='diffa'; e.g2F=1.0; e.g2Fend=0.3; e.g2FendFrac=0.7; e.g2Pool='pool'; e.g2Anchor='any'; % E: 后30% F->0.3
algs=repmat({'SGWO_STEER3'},1,5);
labels={'A-Frozen','B-F10','C-Late07-05','D-Late05-05','E-Late07-03'};
opt=struct('states',{ {a,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
