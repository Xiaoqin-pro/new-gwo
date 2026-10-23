function out=screen84_idc_p0(seeds,maxFE,D,funcs,tag)
%SCREEN84_IDC_P0  Identity-Credit premise audit on the frozen final implementation (docs/77).
if nargin<1 || isempty(seeds), seeds=3549:3553; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 13 20 30]; end
if nargin<5 || isempty(tag), tag='idc_p0'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'steerMode','perwolf','sdirSource','random', ...
    'succSteer',0.5,'steerLambda',0.5);
armA=common; armA.idcStableID=0; armA.idcResetOnRefresh=0; armA.idcAudit=1;
armB=common; armB.idcStableID=1; armB.idcResetOnRefresh=1;
armC=common; armC.idcStableID=1; armC.idcResetOnRefresh=0;
armD=common; armD.idcStableID=0; armD.idcResetOnRefresh=1;
algs=repmat({'SGWO_IDC'},1,4);
labels={'A-Audit','B-ID+Reset','C-IDonly','D-Resetonly'}; labels{4}='D-ResetOnly';
opt=struct(); opt.states={armA,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
