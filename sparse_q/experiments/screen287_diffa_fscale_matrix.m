function out=screen287_diffa_fscale_matrix(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4454:4463; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='diffa_fscale_matrix'; end
base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random','ablateG2',0,'ablateE',0, ...
    'steerMode','perwolf','sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'opPolicy','fixed','opFixed',1,'opDiffMode','nowarc','opF',0.5, ...
    'g2Mode','shell','g2F',0.5,'g2Pool','pool');
a=base;                              % A: 冻结
% 联合矩阵：g2F x g2DiffScale（保留 r1 权重 vs 差分噪声幅度）
c1=a; c1.g2Mode='diffa'; c1.g2F=0.75; c1.g2DiffScale=1.0; c1.g2Pool='pool'; c1.g2Anchor='any';  % C1: F0.75 DS1.0
c2=a; c2.g2Mode='diffa'; c2.g2F=0.75; c2.g2DiffScale=0.75; c2.g2Pool='pool'; c2.g2Anchor='any'; % C2: F0.75 DS0.75
c3=a; c3.g2Mode='diffa'; c3.g2F=0.75; c3.g2DiffScale=0.5; c3.g2Pool='pool'; c3.g2Anchor='any';  % C3: F0.75 DS0.5
c4=a; c4.g2Mode='diffa'; c4.g2F=1.0; c4.g2DiffScale=0.75; c4.g2Pool='pool'; c4.g2Anchor='any';  % C4: F1.0 DS0.75
c5=a; c5.g2Mode='diffa'; c5.g2F=1.0; c5.g2DiffScale=1.0; c5.g2Pool='pool'; c5.g2Anchor='any';   % C5: F1.0 DS1.0 (冠军配置)
c6=a; c6.g2Mode='diffa'; c6.g2F=0.5; c6.g2DiffScale=1.0; c6.g2Pool='pool'; c6.g2Anchor='any';   % C6: F0.5 DS1.0
algs=repmat({'SGWO_STEER3'},1,7);
labels={'A-Frozen','C1-F075DS10','C2-F075DS075','C3-F075DS05','C4-F10DS075','C5-F10DS10','C6-F05DS10'};
opt=struct('states',{ {a,c1,c2,c3,c4,c5,c6} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
