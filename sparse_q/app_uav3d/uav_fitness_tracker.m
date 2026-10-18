classdef uav_fitness_tracker < handle
%UAV_FITNESS_TRACKER  适应度包装（handle 类）：记录真实 FE、可行性轨迹、
%   首次可行 FE 与初始种群评价，供 UAV 应用适配器使用。
    properties
        evalFcn; model; uavState; maxEval; pop;
        feCount = 0; feasTrace; firstFeasible = NaN; initCosts; initFeas;
        ckptFE = [2000 5000 10000 20000 30000];    % 预注册 FE 检查点
        ckptHadFeasible; ckptBestFeasCost; ckptBestFeasDistance; ckptBestFeasWaiting;
        ckptBestPenalized;
        bestFeasCost = NaN; bestFeasDist = NaN; bestFeasWait = NaN; bestPen = NaN;
    end
    methods
        function obj = uav_fitness_tracker(evalFcn,model,uavState,maxEval,pop)
            obj.evalFcn = evalFcn;
            obj.model = model; obj.uavState = uavState;
            obj.maxEval = maxEval; obj.pop = pop;
            obj.feasTrace = false(maxEval,1);
            obj.initCosts = nan(pop,1); obj.initFeas = false(pop,1);
            nC = numel(obj.ckptFE);
            obj.ckptHadFeasible = false(1,nC);
            obj.ckptBestFeasCost = nan(1,nC); obj.ckptBestFeasDistance = nan(1,nC);
            obj.ckptBestFeasWaiting = nan(1,nC); obj.ckptBestPenalized = nan(1,nC);
        end
        function c = eval(obj,x)
            % 严格 FE 审计：预算外调用直接报错（与 CEC 探针同标准）
            if obj.feCount >= obj.maxEval
                error('uav_fitness_tracker:BudgetExceeded', ...
                    'Fitness called beyond the FE budget (%d).',obj.maxEval);
            end
            [c,dt] = obj.evalFcn(x,obj.model,obj.uavState);
            obj.feCount = obj.feCount + 1;
            obj.feasTrace(obj.feCount) = dt.feasible;
            if obj.feCount<=obj.pop
                obj.initCosts(obj.feCount) = c;
                obj.initFeas(obj.feCount) = dt.feasible;
            end
            if isnan(obj.bestPen) || c<obj.bestPen, obj.bestPen = c; end
            if dt.feasible && (isnan(obj.bestFeasCost) || c<obj.bestFeasCost)
                obj.bestFeasCost = c; obj.bestFeasDist = dt.distance;
                obj.bestFeasWait = dt.totalWaiting;
            end
            ci = find(obj.ckptFE == obj.feCount,1);
            if ~isempty(ci)
                obj.ckptHadFeasible(ci) = ~isnan(obj.bestFeasCost);
                obj.ckptBestFeasCost(ci) = obj.bestFeasCost;
                obj.ckptBestFeasDistance(ci) = obj.bestFeasDist;
                obj.ckptBestFeasWaiting(ci) = obj.bestFeasWait;
                obj.ckptBestPenalized(ci) = obj.bestPen;
            end
            if isnan(obj.firstFeasible) && dt.feasible
                obj.firstFeasible = obj.feCount;
            end
        end
    end
end
