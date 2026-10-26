function out=screen306_strat_dev(seeds,maxFE,D,funcs,tag)
%SCREEN306_STRAT_DEV  Stratified unbiased screening vs uniform random.
%   4 arms x 8 functions x 5 seeds, D=50, 100k FE, slots fixed at 50/12/38.
%     W0  uniform random                      (current v2 baseline)
%     W1  strat 3/3/4   balanced per source
%     W2  strat 2/4/4   more weight on DiffA
%     W3  strat 3/4/3   more weight on DiffA, less on E
if nargin<1 || isempty(seeds), seeds=4701:4705; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 4 7 10 13 20 24 30]; end
if nargin<5 || isempty(tag), tag='strat_dev'; end
cfgs={ {'screening','rand'}
       {'screening','strat','kG1',3,'kG2s',3,'kEs',4}
       {'screening','strat','kG1',2,'kG2s',4,'kEs',4}
       {'screening','strat','kG1',3,'kG2s',4,'kEs',3} };
labels={'W0-rand','W1-strat334','W2-strat244','W3-strat343'};
st=cell(1,numel(cfgs));
for k=1:numel(cfgs)
    o=cfgs{k}; s=struct();
    for q=1:2:numel(o), s.(o{q})=o{q+1}; end
    st{k}=s;
end
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,numel(cfgs)),funcs(:),seeds(:),D,maxFE,opt);
end
