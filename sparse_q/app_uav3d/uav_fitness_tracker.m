classdef uav_fitness_tracker < handle
%UAV_FITNESS_TRACKER  适应度包装（handle 类）：记录真实 FE、可行性轨迹、
%   首次可行 FE 与初始种群评价，供 UAV 应用适配器使用。
    properties
        model; uavState; maxEval; pop;
        feCount = 0; feasTrace; firstFeasible = NaN; initCosts; initFeas;
    end
    methods
        function obj = uav_fitness_tracker(model,uavState,maxEval,pop)
            obj.model = model; obj.uavState = uavState;
            obj.maxEval = maxEval; obj.pop = pop;
            obj.feasTrace = false(maxEval,1);
            obj.initCosts = nan(pop,1); obj.initFeas = false(pop,1);
        end
        function c = eval(obj,x)
            % 严格 FE 审计：预算外调用直接报错（与 CEC 探针同标准）
            if obj.feCount >= obj.maxEval
                error('uav_fitness_tracker:BudgetExceeded', ...
                    'Fitness called beyond the FE budget (%d).',obj.maxEval);
            end
            [c,dt] = Fitness(x,obj.model,obj.uavState);
            obj.feCount = obj.feCount + 1;
            obj.feasTrace(obj.feCount) = dt.feasible;
            if isnan(obj.firstFeasible) && dt.feasible
                obj.firstFeasible = obj.feCount;
            end
            if obj.feCount <= obj.pop
                obj.initCosts(obj.feCount) = c;
                obj.initFeas(obj.feCount) = dt.feasible;
            end
        end
    end
end
