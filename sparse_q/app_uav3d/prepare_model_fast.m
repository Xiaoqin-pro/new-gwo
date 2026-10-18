function model = prepare_model_fast(model)
%PREPARE_MODEL_FAST  为模型预建快速地形插值器（一次构建，供 FitnessFast 使用）。
%   网格与 interp2(model.X,model.Y,model.terrainZ,.,'linear') 完全一致：
%   x=model.X(1,:), y=model.Y(:,1)'，V=terrainZ'（griddedInterpolant 的列主序约定）；
%   线性插值 + 'none' 外插（网格外返回 NaN，与 interp2 默认行为一致）。
x=model.X(1,:); y=model.Y(:,1)';
model.terrainF=griddedInterpolant({x,y},model.terrainZ','linear','none');
end
