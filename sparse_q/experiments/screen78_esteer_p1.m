function out=screen78_esteer_p1(seeds,maxFE,D,funcs,tag)
%SCREEN78_ESTEER_P1  2x2 factorial: {G1-STEER on/off} x {E-STEER on/off} on the frozen scaffold.
%   A = G1 on / E off (frozen final), B = G1 off / E on, C = both on, D = both off (frozen G1+E).
%   Pre-registration: sparse_q/docs/70_ESTEER_P1_PREREG.md
if nargin<1 || isempty(seeds), seeds=3449:3458; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3 4 7 10 11 13 14 16 18 20 22 24 26 30]; end
if nargin<5 || isempty(tag), tag='esteer_p1'; end
common=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random', ...
    'ablateG2',1,'ablateE',0,'sdirSource','random','succSteer',0.5,'steerLambda',0.5, ...
    'esteerProb',0.5,'esteerLambda',0.5,'esteerSeedOffset',777001);
armA=common; armA.steerMode='perwolf'; armA.esteerMode='none';
armB=common; armB.steerMode='none';    armB.esteerMode='rand';
armC=common; armC.steerMode='perwolf'; armC.esteerMode='rand';
armD=common; armD.steerMode='none';    armD.esteerMode='none';
algs=repmat({'SGWO_ESTEER'},1,4);
labels={'A-G1on-Eoff','B-G1off-Eon','C-G1on-Eon','D-G1off-Eoff'};
opt=struct(); opt.states={armA,armB,armC,armD}; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
