function out=screen24_g2afe(seeds,maxFE,D,funcs,tag)
%SCREEN24_G2AFE  Pre-registered P1 for the G2 archive-frontier extrapolation arm.
%   Defaults: D=50, F3/5/8/12/17/20/23/30, seeds 3111:3120, 30k true FE,
%   exactly 4 local workers. Optional overrides exist only for the pre-registered
%   smoke test; they do not change the default P1 protocol.
if nargin<1 || isempty(seeds), seeds=3111:3120; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[3 5 8 12 17 20 23 30]; end
if nargin<5 || isempty(tag), tag='g2afe_p1'; end

base=struct('mode','sparse','K',10,'nG2',12,'nE',38,'screenPolicy','random');
a2=base; a2.ablateG2=1;                 % G1+E; G2 slots filled by standard GWO proposals

afe=base;                               % trigger-gated directed extrapolation
afe.g2AFEAlways=0; afe.g2AFERandomDir=0;
afe.g2AFETriggerFrac=0.05; afe.g2AFEMinArc=4; afe.g2AFEMinPairFrac=0.005;
afe.g2AFELambdaMin=0.25; afe.g2AFELambdaMax=0.75; afe.g2AFEEpsFrac=0.05;

rd=afe; rd.g2AFERandomDir=1;            % matched direction control
alw=afe; alw.g2AFEAlways=1;             % no stagnation trigger

algs  ={'SGWO','SGWOAB','SGWO_AFE','SGWO_AFE','SGWO_AFE'};
labels={'V1-frozen','A2-G1E','G2-AFE-Trigger','G2-AFE-RandomDir','G2-AFE-Always'};
states=cell(1,5);
states{2}=a2; states{3}=afe; states{4}=rd; states{5}=alw;

opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_sq(tag,algs,funcs,seeds,D,maxFE,opt);
end
