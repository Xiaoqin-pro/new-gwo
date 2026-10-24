function out=screen284_diffa_scale_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4424:4433; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_scale_dev10'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结
f=base; f.g2Mode='diffa'; f.g2F=1.0; f.g2Pool='pool'; f.g2Anchor='any'; f.g2DiffScale=1.0; % F: 冠军配置
b=f; b.g2DiffScale=0.0;              % B: 差分项=0 (纯 toward-alpha)
c=f; c.g2DiffScale=0.3;              % C: 差分项 0.3
d=f; d.g2DiffScale=0.5;              % D: 差分项 0.5
e=f; e.g2DiffScale=0.75;             % E: 差分项 0.75
algs=repmat({'SGWO_STEER3'},1,6);
labels={'A-Frozen','B-Scale00','C-Scale03','D-Scale05','E-Scale075','F-Scale10'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
