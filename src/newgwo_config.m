function cfg=newgwo_config()
%NEWGWO_CONFIG  Central paths for NEW_GWO_2026.
%   External directories are READ-ONLY reference material (audited baselines,
%   the audited CEC2017 harness); nothing here is ever written outside the
%   NEW_GWO_2026 project root.
root=fileparts(fileparts(mfilename('fullpath')));
cfg=struct();
cfg.root=root;
cfg.cecDir=fullfile(root,'data','cec2017');
cfg.wolfDir='D:\111\Desktop\噜噜\狼群';
cfg.saqDir='D:\111\Desktop\噜噜\9.29';
cfg.auditRuns10=fullfile(root,'data','reference','audited_10algo_30seed.csv');
cfg.auditRuns15=fullfile(root,'data','reference','audited_15algo_30seed.csv');
end
