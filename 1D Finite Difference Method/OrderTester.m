% Compute order for 1D Finite Difference Problems for Conservation Laws

function [output_table] = OrderTester(discretizationType, lambda, tf, u0, f, u_exact_eqn)
    Nxvals = [40, 80, 160, 320, 640]';
    interval = [0, 2*pi];    
    alpha = 1;
    
    errors = zeros(numel(Nxvals), 2); % L1, L2 errors
    
    for i = 1:size(errors, 1)
        Nx = Nxvals(i);
        xvals = linspace(interval(1), interval(2), Nx+1)';
        dx = xvals(2) - xvals(1);
        xmid = xvals(1:end-1) + dx/2; 

        % compute exact solution
        % for j = 1:Nx
        %     u_exact(j, 1) = burgers_soln(xmid(j), tf, @(x) sin(x));
        % end
        u_exact = u_exact_eqn(xmid);
        
        u = Finite_Differences(discretizationType, Nx, lambda, interval, tf, f, u0, alpha);
        errors(i, 1) = dx*(sum(abs(u - u_exact))); % L1 error
        errors(i, 2) = sqrt(dx*sum((u - u_exact).^2)); % L2 error
    end
    
    figure; clf;
    plot(xmid+(tf*sin(xmid)), sin(xmid) , 'black--'); hold on; % burgers equation
    %plot(xmid, u_exact , 'black--'); hold on; % anything else
    plot(xmid, u, 'b-', 'LineWidth', 1.5);
    title(sprintf('WENO5 + %s at t=%s', discretizationType, num2str(tf, 2)));
    xlabel('x'); ylabel('u'); legend('Exact', sprintf('Nx=%d', numel(xvals)-1));

    L1_error = errors(:, 1);
    L2_error = errors(:, 2);
    L1_order = [0; log2(errors(1:end-1, 1) ./ errors(2:end, 1))];
    L2_order = [0; log2(errors(1:end-1, 2) ./ errors(2:end, 2))];
    
    output_table = table(L1_error, L1_order, L2_error, L2_order);
end


function u = burgers_soln(x,t,u0)
    F1 = @(x0) x0 + t.*sin(x0) - x;
    x0 = fzero(F1,[0,2*pi]);
    u = u0(x0);
end




