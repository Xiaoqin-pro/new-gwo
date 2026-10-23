function out=screen138_nmlshade_p1(seeds,maxFE,D,funcs,tag)
%SCREEN138_NMLSHADE_P1  Niche-migration L-SHADE independent P1.
if nargin<1 || isempty(seeds), seeds=3829:3838; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='nmlshade_p1'; end
common=struct('migFrac',0.25,'migBankCap',32,'migBankSep',0.02, ...
    'migProgressFrac',0.05,'migPlateauTol',5e-4,'migPeriodicFrac',0.10);
armA=common; armA.migMode='off';
armB=common; armB.migMode='periodic_niche';
armC=common; armC.migMode='plateau_random';
armD=common; armD.migMode='plateau_niche';
algs=repmat({'NMLSHADE'},1,4);
labels={'A-LS-Off','B-PeriodicNiche','C-PlateauRandom','D-PlateauNiche'};
opt=struct('states',{ {armA,armB,armC,armD} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
