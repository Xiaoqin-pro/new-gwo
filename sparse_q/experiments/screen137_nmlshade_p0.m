function out=screen137_nmlshade_p0(seeds,maxFE,D,funcs,tag)
%SCREEN137_NMLSHADE_P0  Niche-migration L-SHADE P0.
if nargin<1 || isempty(seeds), seeds=3824:3828; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='nmlshade_p0'; end
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
