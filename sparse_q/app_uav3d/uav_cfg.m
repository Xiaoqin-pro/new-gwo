function cfg = uav_cfg(mapID, nOrders)
%UAV_CFG  benchmark-v1 应用配置（与 9.29/archive/legacy/main.m 完全一致）。
%   mapID: 1=ridge, 2=peaks, 3=mountain, 4=hills, 5=plateau
if nargin<2 || isempty(nOrders), nOrders=20; end
root=fileparts(mfilename('fullpath'));
cfg.threatFile=fullfile(root,'data','threat_zones.csv');
names={'ridge','peaks','mountain','hills','plateau'};
cfg.terrainFiles=cellfun(@(n) fullfile(root,'data',['map_' n '.mat']),names,'UniformOutput',false);
cfg.mapSize=[100 100];
cfg.terrainType=mapID;
cfg.depotXY=[40 50];
cfg.depotWindow=[0 360];
cfg.speed=10;
cfg.serviceHeight=16;
cfg.minClearance=4;
cfg.maxAltitude=42;
cfg.maxClimbAngle=35;
cfg.maxTurnAngle=120;
cfg.nControlPoints=3;
cfg.minControlRatio=0.2;
cfg.maxControlRatio=0.8;
cfg.maxSideOffset=4;
cfg.minHeightOffset=0;
cfg.maxHeightOffset=4;
cfg.smoothWeight=2;
cfg.nOrders=nOrders;
cfg.stationFile=fullfile(root,'data','map_scenarios_v6',sprintf('N20_%s.csv',names{mapID}));
end
