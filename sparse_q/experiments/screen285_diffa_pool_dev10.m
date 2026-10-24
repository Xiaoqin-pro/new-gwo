function out=screen285_diffa_pool_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4434:4443; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_pool_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结
b=base; b.g2Mode='diffa'; b.g2F=1.0; b.g2Pool='pool'; b.g2Anchor='any';      % B: pool（冠军）
c=base; c.g2Mode='diffa'; c.g2F=1.0; c.g2Pool='wolves'; c.g2Anchor='any';    % C: wolves
d=base; d.g2Mode='diffa'; d.g2F=1.0; d.g2Pool='archive'; d.g2Anchor='any';    % D: archive
e=base; e.g2Mode='diffa'; e.g2F=1.0; e.g2Pool='archive'; e.g2Anchor='best';   % E: archive-best
algs=repmat({'SGWO_STEER3'},1,5);
labels={'A-Frozen','B-Pool','C-Wolves','D-Archive','E-ArchiveBest'};
opt=struct('states',{ {a,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
