function verify_witness()
%VERIFY_WITNESS  独立复核 benchmark-v1 见证：用本目录代码重建模型并重评决策向量，
%   与存档指标逐项比对（论文附录可复现性材料）。
%   说明：data/witness/legacy_v3_tight/ 与 v6_*_witness.csv 属旧实例记录，仅存档。
here=fileparts(mfilename('fullpath')); sq=fileparts(here);
cfg0=newgwo_config();
addpath(here,fullfile(sq,'src'),fullfile(cfg0.root,'src'));
S=load(fullfile(here,'data','witness','witness_v1.mat'));
witness=S.witness;
fprintf('== verify_witness (benchmark-v1, 5 maps) ==\n');
for k=1:numel(witness)
    w=witness(k);
    cfg=uav_cfg(w.MapID); model=CreateModel(cfg);
    st.time=0; st.position=model.depot; st.activeIDs=model.activeIDs;
    st.maxEvaluations=w.Evaluations;
    [c,dt]=Fitness(w.Vector,model,st);
    fprintf('  %-8s cost %9.3f -> %9.3f  feasible %d  distance %8.3f -> %8.3f  viol %g\n', ...
        w.Map,w.Cost,c,w.Feasible,w.Distance,dt.distance,w.Violations);
    assert(abs(c-w.Cost)<=1e-6*max(1,abs(w.Cost)),'cost mismatch');
    assert(dt.feasible==w.Feasible,'feasibility mismatch');
    assert(abs(dt.distance-w.Distance)<=1e-6*max(1,w.Distance),'distance mismatch');
end
assert(all([witness.Feasible]),'not all witnesses feasible');
fprintf('  ==> all 5 witnesses independently reproduced. OK\n');
end
