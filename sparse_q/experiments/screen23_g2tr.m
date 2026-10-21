function out=screen23_g2tr(seeds,maxFE,D,funcs,tag)
%SCREEN23_G2TR  Pre-registered P1 rescue experiment for the G2 trust-region arm.
%   out=screen23_g2tr() uses D=50, F1/F4/F6/F9/F11/F15/F21/F25,
%   seeds 3101:3110, 30,000 true FE, exactly 4 local workers.
%   Optional overrides exist only for the pre-registered smoke test; the
%   default arguments are the P1 protocol frozen in docs/19_G2TR_PREREG.md.
if nargin<1 || isempty(seeds), seeds=3101:3110; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 6 9 11 15 21 25]; end
if nargin<5 || isempty(tag), tag='g2tr_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');

a2=base; a2.ablateG2=1;              % G1+E; G2 slots filled by standard GWO proposals
a4=base; a4.sigmaFixFrac=0.001;      % legacy shell geometry, fixed at the trust-region floor
tr=base;                             % G2-TR: only the radius rule differs
tr.g2RadiusMode='trust';
tr.g2R0=0.01; tr.g2RMin=0.001; tr.g2RMax=0.05;
tr.g2Expand=1.25; tr.g2Shrink=0.8;
sub=base; sub.g2Subset=0.20;         % coordinate-sparse alternative control

algs  ={'SGWO','SGWOAB','SGWOAB','SGWO_TR','SGWOAB'};
labels={'V1-frozen','A2-G1E','A4-G2fixedmin','G2-TR','G2-subset20'};
states=cell(1,5);
states{2}=a2; states{3}=a4; states{4}=tr; states{5}=sub;

opt=struct();
opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
