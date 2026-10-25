function [UpdatedPositions, UpdatedFit] = DualMutationScheme(Positions, SelectedIndividuals, Fit, fobj, Alpha_pos, Beta_pos, Delta_pos, iter, Max_iter)
    % Determine global bounds across all positions
    allPositions = Positions;
    lb_all = min(allPositions, [], 1);
    ub_all = max(allPositions, [], 1);

    % Control the steepness of the Sigmoid function
    c = 0.05;
    progress = 1 / (1 + exp(- c * (iter - Max_iter / 2)));
    p_cauchy = 0.4 * (1 - progress);

    % Nonlinear leadership weights (exponential adjustment)
    w_alpha = 0.5 + 0.5/(1 + exp(-10*(progress-0.5)));  
    w_beta  = 0.3 * exp(-3*progress);                    
    w_delta = 0.2 * exp(-5*progress);                    
    
    % Normalize weights
    total_w = w_alpha + w_beta + w_delta;
    w_alpha = w_alpha / total_w;
    w_beta  = w_beta  / total_w;
    w_delta = w_delta / total_w;

    % Nonlinear step size control
    base_step    = 0.5 * (1 - progress^1.5);      
    chaos_factor = 1.1 + 0.2 * sin(20 * progress);      

    %% Step 1: Remove SelectedIndividuals from the population
    removalIndices = [];
    for i = 1:size(Positions, 1)
        for j = 1:size(SelectedIndividuals, 1)
            if all(Positions(i, :) == SelectedIndividuals(j, :))
                removalIndices = [removalIndices; i];
                break;
            end
        end
    end
    Positions(removalIndices, :) = [];     % Remove the corresponding individuals
    Fit(removalIndices, :)       = [];     % Remove the corresponding fitness values

    %% Step 2: Perform non-dominated sorting on the remaining population
    [SortedPositions, DominanceRank] = NonDominatedSorting(Positions, Fit);

    %% Step 3: Mutate selected individuals
    for i = 1:size(SelectedIndividuals, 1)
        Xi_PI = SelectedIndividuals(i, :);
        
        % Choose mutation strategy based on dominance and dynamic trigger probability
        if isDominated(Xi_PI, SortedPositions, DominanceRank) && (rand < p_cauchy)
            % Cauchy mutation: heavy-tailed distribution suitable for global search
            delta = tan(pi * (rand(1, length(Xi_PI)) - 0.5));
            Ii = Xi_PI + (ub_all - lb_all) .* delta;
        else
            % Polynomial mutation for local search
            r     = rand(size(Xi_PI));
            eta_m = 20;
            delta = (r < 0.5) .* ((2 * r).^(1 / (eta_m + 1)) - 1) + ...
                    (r >= 0.5) .* (1 - (2 * (1 - r)).^(1 / (eta_m + 1)));
            Ii = Xi_PI + (ub_all - lb_all) .* delta;
        end

        %% Improved olfactory direction correction
        % Compute dynamic leader center
        leader_center = w_alpha * Alpha_pos + w_beta * Beta_pos + w_delta * Delta_pos;
        
        % Compute direction correction
        direction = leader_center - Xi_PI;
        step_size = base_step * chaos_factor;
        
        % Fitness-based adaptive scaling
        alpha_dist     = norm(Alpha_pos - Xi_PI);
        adaptive_scale = 1 / (1 + exp(-alpha_dist / mean(ub_all - lb_all)));
        Ii = Ii + step_size .* direction * adaptive_scale;
       
        % Apply boundary constraints using globally computed bounds
        lu = [lb_all; ub_all];
        Ii = boundConstraint(Ii, Xi_PI, lu);

        %% Update population with mutated individual
        Positions      = [Positions; Ii];
        newFitValue    = fobj(Ii);
        Fit            = [Fit; newFitValue];
    end

    UpdatedPositions = Positions;
    UpdatedFit       = Fit;
end

function flag = isDominated(individual, Positions, ~)
    % Determine if the individual is dominated by any other individual
    flag = false;
    for i = 1:size(Positions, 1)
        if all(Positions(i, :) <= individual) && any(Positions(i, :) < individual)
            flag = true;
            break;
        end
    end
end
