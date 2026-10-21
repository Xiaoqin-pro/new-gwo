function out=screen27_vacg(seeds,maxFE,D,funcs,tag)
%SCREEN27_VACG  Pre-registered P1 for CD-VACG with matched RandomSplit control.
if nargin<1 || isempty(seeds), seeds=3131:3140; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[7 10 13 16 18 22 24 30]; end
if nargin<5 || isempty(tag), tag='vacg_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
mad=base; mad.vacgOn=1; mad.vacgMode='mad';
mad.vacgTopFrac=0.25; mad.vacgNoise=0.25; mad.vacgMinArc=3; mad.vacgSeedOffset=555555;
rnd=mad; rnd.vacgMode='random';

algs  ={'SGWO','SGWO_VACG','SGWO_VACG'};
labels={'V1-Frozen','CD-VACG-MAD','CD-VACG-RandomSplit'};
states=cell(1,3); states{2}=mad; states{3}=rnd;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
