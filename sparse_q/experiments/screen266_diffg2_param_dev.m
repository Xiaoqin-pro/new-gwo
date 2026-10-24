function out=screen266_diffg2_param_dev(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4317:4318; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 5 6 7 8 9 10 11 13 14 18 20 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffg2_param_dev'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                                   % A: 冻结（shell G2）
b=base; b.g2Mode='diff'; b.g2F=0.5; b.g2Pool='pool';      % B: diff12 pool F0.5
c=base; c.g2Mode='diff'; c.g2F=1.0; c.g2Pool='pool';      % C: diff12 pool F1.0
d=base; d.g2Mode='diff'; d.g2F=0.5; d.g2Pool='wolves';    % D: diff12 wolves F0.5
e=base; e.g2Mode='diff'; e.g2F=0.5; e.g2Pool='pool'; e.nG2=6; e.nE=44;  % E: diff6 pool F0.5 (nE补齐到44)
f=base; f.g2Mode='diff'; f.g2F=0.5; f.g2Pool='pool'; f.nG2=18; f.nE=32; % F: diff18 pool F0.5 (nE=32)
algs=repmat({'SGWO_STEER3'},1,6);
labels={'A-ShellG2','B-DiffG2-12-F05-pool','C-DiffG2-12-F10-pool','D-DiffG2-12-F05-wolves','E-DiffG2-6-F05-pool','F-DiffG2-18-F05-pool'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
