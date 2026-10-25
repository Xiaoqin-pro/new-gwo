function out=screen281_diffa_mix_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4404:4413; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_mix_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结 (shell G2)
b=base; b.g2Mode='diffa'; b.g2F=1.0; b.g2Pool='pool'; b.g2Anchor='any';      % B: 全差分 F=1.0 any (29x30 0.904)
c=base; c.g2Mode='mix'; c.g2F=1.0; c.g2Fend=0.3; c.g2Pool='pool'; c.g2Anchor='any'; % C: 混合 6shell+6diffa F1->0.3
d=base; d.g2Mode='mix'; d.g2F=1.0; d.g2Pool='pool'; d.g2Anchor='any';                 % D: 混合 6shell+6diffa F=1.0
e=base; e.g2Mode='mix'; e.g2F=1.0; e.g2Fend=0.3; e.g2Pool='pool'; e.g2Anchor='best';  % E: 混合 anchor-best
algs=repmat({'SGWO_STEER3'},1,5);
labels={'A-Frozen','B-DiffA-F10','C-Mix-Fdecay','D-Mix-F10','E-Mix-FdecayBest'};
opt=struct('states',{ {a,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
