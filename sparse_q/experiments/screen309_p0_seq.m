function out=screen309_p0_seq(seeds,maxFE,D,funcs,tag)
if nargin<1 || isempty(seeds), seeds=4801:4806; end
if nargin<2 || isempty(maxFE), maxFE=100000; end
if nargin<3 || isempty(D), D=50; end
if nargin<4 || isempty(funcs), funcs=[1 3:30]; end
if nargin<5 || isempty(tag), tag='p0_seq_alt'; end
st={ struct('screening','rand'), ...
     struct('evalMode','seq','seqRank','alpha'), ...
     struct('evalMode','seq','seqRank','maximin') };
st{4}=struct('evalMode','seq','seqRank','alt');
labels={'Q0-batch-rand','Q1-seq-alpha','Q2-seq-maximin','Q4-seq-alt'};
opt=struct('states',{st},'labels',{labels});
out=run_batch_sq(tag,repmat({'SVADGWO2_CFG'},1,4),funcs(:),seeds(:),D,maxFE,opt);
end
