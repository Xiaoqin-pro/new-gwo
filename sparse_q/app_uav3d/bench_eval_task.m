function bench_eval_task(nEval,taskID)
%BENCH_EVAL_TASK  单 worker 任务：构建模型并执行 nEval 次 FitnessFast 评价。
cfgT=uav_cfg(1); mT=prepare_model_fast(CreateModel(cfgT));
stT.time=0; stT.position=mT.depot; stT.activeIDs=mT.activeIDs;
D=mT.nOrders+3*(mT.nOrders+1)*mT.nControlPoints;
rng(100+taskID); XT=rand(nEval,D);
for k=1:nEval, [~,~]=FitnessFast(XT(k,:),mT,stT); end
end
