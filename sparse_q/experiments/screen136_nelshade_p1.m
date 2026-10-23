function out=screen136_nelshade_p1(seeds,maxFE,D,funcs,tag)
%SCREEN136_NELSHADE_P1  NE-LSHADE independent P1.
if nargin<1 || isempty(seeds), seeds=3804:3813; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='nelshade_p1'; end
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
