% Discretize in time the Vlasov-Poisson Equation
% Choose between RK1, RK2, RK3, RK4
% Inputs:
%   type - discretization type (RK1, RK2, RK3, RK4)
%   f - numerical solution at time t^n 
%   tn - time t^n 
%   dt, X, V
% Output:
%   f - numerical solution at time t^n+1

function [f] = Time_Discretization_Nonsplitting(type, f, tn, dt, X, V)
    dx = X(2, 1) - X(1, 1);
    dv = V(1, 2) - V(1, 1);

    [F0, G0] = GetFlux(X, V, f, dx, dv); % F is horizontal flux, G is vertical

    switch type
        case 'RK1'
            f = f + (dt)*((F0/dx) + (G0/dv));
        case 'RK2'
            % Stage 1
            f1 = f + (dt)*((F0/dx) + (G0/dv)); % at time t1 = tn+dt
    
            % Stage 2
            t1 = tn + dt;
            [F1, G1] = GetFlux(X, V, f1, dx, dv);

            f = f + ((dt/(2*dx))*(F0 + F1)) + ((dt/(2*dv))*(G0 + G1));
        case 'RK3'
            % Stage 1
            f1 = f + (dt)*((F0/dx) + (G0/dv));
    
            % Stage 2
            t1 = tn + dt;
            [F1, G1] = GetFlux(X, V, f1, dx, dv);

            f2 = f + ((dt/(4*dx))*(F0 + F1)) + ((dt/(4*dv))*(G0 + G1)); % at time t2 = tn + dt

            % Stage 3
            t2 = tn + dt/2;
            [F2, G2] = GetFlux(X, V, f2, dx, dv);

            f = f + ((dt/(dx))*((F0/6) + (F1/6) + (F2*2/3))) + ((dt/(dv))*((G0/6) + (G1/6) + (G2*2/3))); 
        otherwise % RK4
            % Stage 1
            f1 = f + (dt/2)*((F0/dx) + (G0/dv));
    
            % Stage 2
            t1 = tn + dt/2;
            [F1, G1] = GetFlux(X, V, f1, dx, dv);

            f2 = f + ((dt/(2*dx))*(F1)) + ((dt/(2*dv))*(G1)); % at time t2 = tn + dt

            % Stage 3
            t2 = tn + dt/2;
            [F2, G2] = GetFlux(X, V, f2, dx, dv);

            f3 = f + ((dt/(dx))*(F2)) + ((dt/(dv))*(G2)); 

            % Stage 4
            t3 = tn + dt;
            [F3, G3] = GetFlux(X, V, f3, dx, dv);

            f = f + ((dt/(6*dx))*(F0 + 2*F1 + 2*F2 + F3)) + ((dt/(6*dv))*(G0 + 2*G1 + 2*G2 + G3)); 
    end
end

function [F, G] = GetFlux(X, V, f, dx, dv)
    % inputs: 
    %   X, V - x, velocity
    %   f - numerical solution at time t^n
    %   dx, dv
    % output: 
    %   F, G - numerical fluxes F (x-direction), G (v-'direction')
    F = zeros(size(X));
    G = zeros(size(V));

    rho = (dv*sum(f, 2)) - 1; % density over velocity (velocity integral) scaled with -1
    Nx = size(X, 1);
    xLength = X(end, 1) - X(1, 1) + dx;
    EF = poisson(rho, Nx, xLength); % use Poisson's Equation to solve for Electric Field E

    xFlux = @(f, v) v.*f;
    alpha = max(max(abs(V)));
    vFlux = @(f, E) E.*f;
    beta = max(abs(EF));
    
    % first iterate to find F
    for i = 1:size(f, 2) % hold v constant, vary x
        vmid = V(:, i); 
        f_pos = (xFlux(f(:, i), vmid) + (alpha.*f(:, i)))/2;
        f_neg = (xFlux(f(:, i), vmid) - (alpha.*f(:, i)))/2;
        F(:, i) = ComputeFluxDifference(f_pos, f_neg);
    end

    % iterate to find G
    for j = 1:size(f, 1) % hold x constant, vary v
        g_pos = (vFlux(f(j, :)', EF(j)) + (beta.*f(j, :)'))/2; 
        g_neg = (vFlux(f(j, :)', EF(j)) - (beta.*f(j, :)'))/2;
        
        G(j, :) = ComputeFluxDifference(g_pos, g_neg);
    end
end

function [F] = ComputeFluxDifference(f_pos, f_neg)
    % computes the difference between fluxes at right/left boundaries for a
    % given cell
    flux_left_lim = WENO(f_pos, 1); % left limit, right boundary
    flux_right_lim = WENO(f_neg, 0); % right limit, left boundary
    flux_right_lim = [flux_right_lim(2:end); flux_right_lim(1)];
    f_hat_pos = flux_left_lim + flux_right_lim;
    f_hat_neg = [f_hat_pos(end); f_hat_pos(1:end-1)];
    F = -(f_hat_pos - f_hat_neg);
end





























