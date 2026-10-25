function out=screen292_diffa_ng2_final(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4474:4483; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_ng2_final'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','diffa','g2F',1.0,'g2Fend',0.3,'g2FendFrac',0.7,'g2Pool','pool','g2Anchor','any');
a=base;                              % A: nG2=12 nE=38 (当前最终)
b=base; b.nG2=4;  b.nE=46;           % B: 4 差分槽位
c=base; c.nG2=8;  c.nE=42;           % C: 8 差分槽位
d=base; d.nG2=16; d.nE=34;           % D: 16 差分槽位
e=base; e.nG2=24; e.nE=26;           % E: 24 差分槽位
algs=repmat({'SGWO_STEER3'},1,5);
labels={'A-G2-12','B-G2-04','C-G2-08','D-G2-16','E-G2-24'};
opt=struct('states',{ {a,b,c,d,e} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
