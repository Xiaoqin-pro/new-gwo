function out=screen277_diffa_sensitivity(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4389:4393; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_sensitivity'; end
ba=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Pool','pool','g2Anchor','best');
a=ba;                                   % A: anchor-best F1.0 pool 12/38 (champion)
b=ba; b.g2F=0.75;                       % B: F=0.75
c=ba; c.g2F=1.25;                       % C: F=1.25
d=ba; d.nG2=6;  d.nE=44;                % D: 6 diff slots
e=ba; e.nG2=18; e.nE=32;                % E: 18 diff slots
f=ba; f.nG2=24; f.nE=26;                % F: 24 diff slots
g=ba; g.g2Pool='wolves';                % G: wolves only pool
h=ba; h.g2Anchor='any';                 % H: any anchor (29x30 config ref)
i=ba; i.g2MaxStep=0.5;                  % I: step cap 0.5
algs=repmat({'SGWO_STEER3'},1,9);
labels={'A-AncBest-F10','B-F075','C-F125','D-G2-06','E-G2-18','F-G2-24','G-Wolves','H-AnchAny','I-Step05'};
opt=struct('states',{ {a,b,c,d,e,f,g,h,i} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
