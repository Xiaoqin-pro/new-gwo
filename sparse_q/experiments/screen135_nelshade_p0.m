function out=screen135_nelshade_p0(seeds,maxFE,D,funcs,tag)
%SCREEN135_NELSHADE_P0  NE-LSHADE mechanism screening.
if nargin<1 || isempty(seeds), seeds=3799:3803; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='nelshade_p0'; end
common=struct('ecoNicheCap',24,'ecoSepFrac',0.02,'ecoBaseProb',0.20, ...
    'ecoMinProb',0.10,'ecoMaxProb',0.60,'ecoStagnProb',0.65,'ecoStagnFrac',0.08, ...
    'ecoLeaderK',5,'ecoRescueFrac',0.50,'ecoStallMin',2);
armA=common; armA.ecoMode='off';
armB=common; armB.ecoMode='random_adaptive';
armC=common; armC.ecoMode='niche_fixed';
armD=common; armD.ecoMode='niche_adaptive';
algs=repmat({'NELSHADE'},1,4);
labels={'A-LS-Off','B-RandomAdaptive','C-NicheFixed','D-NicheAdaptive'};
opt=struct('states',{ {armA,armB,armC,armD} },'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
