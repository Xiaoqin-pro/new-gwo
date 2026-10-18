function bench_throughput(nEval)
%BENCH_THROUGHPUT  Fitness vs FitnessFast 单线程与 4-worker 吞吐基准。
if nargin<1 || isempty(nEval), nEval=1000; end
here=fileparts(mfilename('fullpath')); sq=fileparts(here); cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'));
cfg=uav_cfg(1); model=CreateModel(cfg); modelF=prepare_model_fast(model);
st.time=0; st.position=model.depot; st.activeIDs=model.activeIDs;
D=model.nOrders+3*(model.nOrders+1)*model.nControlPoints;
rng(7); X=rand(nEval,D);
t0=tic; for k=1:nEval, [~,~]=Fitness(X(k,:),model,st); end; tStd=toc(t0);
t0=tic; for k=1:nEval, [~,~]=FitnessFast(X(k,:),modelF,st); end; tFast=toc(t0);
fprintf('单线程: Fitness %.2f ms/eval | FitnessFast %.2f ms/eval | 加速 %.2fx\n', ...
    1000*tStd/nEval,1000*tFast/nEval,tStd/tFast);
pool=overnight.ensureFourWorkers(); assert(pool.NumWorkers==4);
nTask=8; t0=tic;
parfor t=1:nTask
    bench_eval_task(nEval,t);
end
wallFast=toc(t0); total=nTask*nEval; rate=total/wallFast;
fprintf('4-worker: %d evals in %.1fs = %.0f evals/s (%.2f M/h)\n',total,wallFast,rate,rate*3600/1e6);
formalHours=900*30000/rate/3600;
fprintf('外推: 聚合 %.0f evals/s → 正式档 900 次 x 30k FE 约 %.1f h（含每次建模开销）\n', ...
    rate,formalHours);
end
