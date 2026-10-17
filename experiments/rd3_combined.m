function out=rd3_combined(seeds,maxFE,D,stateE,stateS,labelE,labelS)
%RD3_COMBINED  Interaction check: best E and best S variants, alone and together.
%   Pre-registered in docs/08_HYPOTHESES_AND_GATES.md; the concrete winner
%   settings are filled in from RD1/RD2 BEFORE this batch is started.
if nargin<1 || isempty(seeds), seeds=3001:3005; end
if nargin<2 || isempty(maxFE), maxFE=30000; end
if nargin<3 || isempty(D), D=30; end
funcs=[1 3 4 6 9 13 18 24];
algs={'GWO','ANGWO','ANGWO','ANGWO'};
labels={'GWO',labelE,labelS,'E+S'};
stE=stateE; stS=stateS;
stES=stateE; fn=fieldnames(stateS);
for k=1:numel(fn), stES.(fn{k})=stateS.(fn{k}); end
states=cell(1,4);
states{2}=stE; states{3}=stS; states{4}=stES;
opt=struct(); opt.states=states; opt.labels=labels;
out=run_batch_new('rd3',algs,funcs,seeds,D,maxFE,opt);
end
