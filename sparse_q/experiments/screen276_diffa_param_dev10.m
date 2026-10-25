function out=screen276_diffa_param_dev10(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4379:4388; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_param_dev10'; end
a=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
b=a; b.g2Mode='diffa'; b.g2Pool='pool'; b.g2F=1.0;                       % 基准（29x30 过的配置）
c=a; c.g2Mode='diffa'; c.g2Pool='pool'; c.g2F=1.0; c.g2MaxStep=0.5;      % 步长截断 0.5
d=a; d.g2Mode='diffa'; d.g2Pool='pool'; d.g2F=1.0; d.g2MaxStep=0.3;      % 步长截断 0.3
e=a; e.g2Mode='diffa'; e.g2Pool='pool'; e.g2F=1.0; e.g2Anchor='best';    % 较好狼锚定
f=a; f.g2Mode='diffa'; f.g2Pool='pool'; f.g2F=1.0; f.g2Anchor='best'; f.g2MaxStep=0.5; % 组合
algs=repmat({'SGWO_STEER3'},1,6);
labels={'A-Frozen','B-DiffA-F10','C-Step05','D-Step03','E-AnchorBest','F-AnchorStep05'};
opt=struct('states',{ {a,b,c,d,e,f} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
