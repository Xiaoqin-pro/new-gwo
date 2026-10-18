function make_witness()
%MAKE_WITNESS  为 benchmark-v1 五张地图生成可复核见证（GWO 基线；见 make_witness_one）。
here=fileparts(mfilename('fullpath')); sq=fileparts(here); cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'));
pool=overnight.ensureFourWorkers(); assert(pool.NumWorkers==4,'exactly 4 workers required');
maps=1:5; N=50; FE=10000; FE2=30000;
W=cell(1,numel(maps));
parfor k=1:numel(maps)
    W{k}=make_witness_one(maps(k),N,FE,FE2);
end
witness=vertcat(W{:});
save(fullfile(here,'data','witness','witness_v1.mat'),'witness');
T=struct2table(witness); T.Vector=[];
disp(T);
fprintf('make_witness done: allFeasible=%d\n',all([witness.Feasible]));
end
