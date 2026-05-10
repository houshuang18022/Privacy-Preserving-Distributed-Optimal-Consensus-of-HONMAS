%% Sensors 2022 - Leaderless MAS Global Consensus with Delay and Saturation (N=10 Version)
clear; clc; close all;

%% Parameters
N = 10;            % number of agents
omega = 3;         % communication delay
c = 0.32;          % control gain parameter
Kmax = 300;        % simulation steps

%% System Matrices (Neutrally Stable)
A = [0 1 0; 
     1/sqrt(2) 0 1/sqrt(2);
    -1/sqrt(2) 0 1/sqrt(2)];
B = [1; 0; 1];
C = [1 1 1];

% Control Gain
K = -c * B' * A;

%% Communication Topology (10-node adjacency matrix)
A_adj = [
    0 1 0 1 1 0 0 0 0 0;
    1 0 1 0 0 1 0 0 0 1;
    0 1 0 1 0 1 0 0 0 0;
    1 0 1 0 0 1 1 0 0 0;
    1 0 0 0 0 0 1 1 1 0;
    0 1 1 1 0 0 1 0 0 0;
    0 0 0 1 1 1 0 1 0 0;
    0 0 0 0 1 0 1 0 1 1;
    0 0 0 0 1 0 0 1 0 1;
    0 1 0 0 0 0 0 1 1 0
];
L = diag(sum(A_adj,2)) - A_adj;

%% Initial States (consistent with nonlinear setup)
x = zeros(3, N, Kmax+1);
x(:,1,1)  = [0;   0;  0];
x(:,2,1)  = [20;  0; 0];
x(:,3,1)  = [-15; 0;  0];
x(:,4,1)  = [8;   0; 0];
x(:,5,1)  = [-10; 0; 0];
x(:,6,1)  = [12;  0;  0];
x(:,7,1)  = [25;  0;  0];
x(:,8,1)  = [-5;  0; 0];
x(:,9,1)  = [18;  0; 0];
x(:,10,1) = [-8;  0; 0];

%% Observer Gain F (ensure A-FC is Schur stable)
if exist('place', 'file')
    F = place(A', C', [0.3 0.4 0.5])';
else
    warning('Control System Toolbox not found. Using default stable F.');
    F = [0.15; 0.1; 0.05];
end

%% Storage
u = zeros(N, Kmax);
x_hat = zeros(3, N, Kmax+1); % predictive state estimates
e = zeros(3, N, Kmax+1);    % estimation errors

%% Saturation function
delta = @(u) max(min(u, 1), -1);

%% Observer and Control Loop
for k = 1:Kmax
    for i = 1:N
        if k > omega
            % Step 1: One-step observer update
            x_hat_temp = A * x_hat(:,i,k-omega) + B * delta(u(i,k-omega));
            y_i = C * x(:,i,k-omega+1);
            x_hat(:,i,k-omega+1) = x_hat_temp + F * (y_i - C * x_hat_temp);

            % Step 2: Predict up to time k
            for step = 1:(omega-1)
                x_hat(:,i,k-omega+1+step) = A * x_hat(:,i,k-omega+step) + B * delta(u(i,k-omega+step));
            end
        else
            x_hat(:,i,k) = x(:,i,k);
        end
    end

    % Control Law using predicted states
    for i = 1:N
        u_temp = zeros(3,1);
        for j = 1:N
            if i ~= j && A_adj(i,j)
                u_temp = u_temp + (x_hat(:,i,k) - x_hat(:,j,k));
            end
        end
        u(i,k) = K * u_temp;
    end

    % System Update
    for i = 1:N
        x(:,i,k+1) = A * x(:,i,k) + B * delta(u(i,k));
    end
end

%% Compute Consensus Error ||Lx||_2
Lx = zeros(Kmax+1, N);
Lx_norm = zeros(1, Kmax+1);
for k = 1:Kmax+1
    x_pos = squeeze(x(1,:,k))';  
    Lx(k,:) = L * x_pos;
    Lx_norm(k) = norm(Lx(k,:), 2);
end

%% Plot Consensus Error ||Lx||_2
figure;
plot(0:Kmax, Lx_norm, 'LineWidth', 1.5);
xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
title('Consensus Error Evolution (10-node Baseline)', 'Interpreter', 'latex');
grid on;

%% Plot States
figure;
for i = 1:N
    plot(squeeze(x(1,i,:)), 'LineWidth', 1.2); hold on;
end
xlabel('Steps');
ylabel('$x_i$', 'Interpreter', 'latex');
legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
title('Position States $x_i$', 'Interpreter', 'latex');
xlim([0, Kmax]);

figure;
for i = 1:N
    plot(squeeze(x(2,i,:)), 'LineWidth', 1.2); hold on;
end
xlabel('Steps');
ylabel('$\dot{x_i}$', 'Interpreter', 'latex');
legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
title('Velocity States $\dot{x_i}$', 'Interpreter', 'latex');
xlim([0, Kmax]);

figure;
for i = 1:N
    plot(squeeze(x(3,i,:)), 'LineWidth', 1.2); hold on;
end
xlabel('Steps');
ylabel('$\ddot{x_i}$', 'Interpreter', 'latex');
legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
title('Acceleration States $\ddot{x_i}$', 'Interpreter', 'latex');
xlim([0, Kmax]);

figure;
for i = 1:N
    plot(u(i,:), 'LineWidth', 1.2); hold on;
end
xlabel('Steps');
ylabel('$u_i$', 'Interpreter', 'latex');
legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
title('Control Inputs $u_i$', 'Interpreter', 'latex');
xlim([0, Kmax]);
