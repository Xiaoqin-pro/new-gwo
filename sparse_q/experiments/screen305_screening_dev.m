function out=screen305_screening_dev(seeds,maxFE,D,funcs,tag)
%SCREEN305_SCREENING_DEV  Screening-policy and slot-ratio development screen.
%   6 arms x 8 functions x 5 seeds, D=50, 100k FE.
%     V0  rand, 50/12/38   current v2 baseline
%     V1  rand, 50/25/25   slot rebalance only
%     V2  geo,  50/25/25   alpha + centroid screening (parameter-free reference)
%     V3  arc,  50/25/25   alpha + verified-archive screening (our proposal)
%     V4  arc,  50/50/50   three balanced sources, archive screening
%     V5  arc,  50/12/38   archive screening at the current ratio
if nargin<1 || isempty(seeds), seeds=4701:4705; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='screening_dev'; end
cfgs={ {'screening','rand','nG2',12,'nE',38}
       {'screening','rand','nG2',25,'nE',25}
       {'screening','geo', 'nG2',25,'nE',25}
       {'screening','arc', 'nG2',25,'nE',25}
       {'screening','arc', 'nG2',50,'nE',50}
       {'screening','arc', 'nG2',12,'nE',38} };
labels={'V0-rand-12/38','V1-rand-25/25','V2-geo-25/25','V3-arc-25/25','V4-arc-50/50','V5-arc-12/38'};
algs=repmat({'SVADGWO2_CFG'},1,numel(cfgs));
st=cell(1,numel(cfgs));
for k=1:numel(cfgs)
    o=cfgs{k}; s=struct();
    for q=1:2:numel(o), s.(o{q})=o{q+1}; end
    st{k}=s;
end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,algs,funcs(:),seeds(:),D,maxFE,opt);
end
