%% Sensors 2022 - Leaderless MAS Global Consensus with Delay and Saturation (N=4 Version)
clear; clc; close all;

%% Parameters
N = 4;            % number of agents
omega = 3;        % communication delay
c = 0.32;         % control gain parameter
Kmax = 300;        % simulation steps

%% System Matrices (Neutrally Stable)
A = [0 1 0; 
     1/sqrt(2) 0 1/sqrt(2);
    -1/sqrt(2) 0 1/sqrt(2)];
B = [1; 0; 1];
C = [1 1 1];

% Control Gain
K = -c * B' * A;

%% Topology (adjacency matrix for 4 agents)
A_adj = [0 1 0 0;
     0 0 1 1;
     0 1 0 1;
     0 1 1 0];
L = diag(sum(A_adj,2)) - A_adj;

%% Initial States (aligned with your nonlinear model)
x = zeros(3, N, Kmax+1);
x(:,1,1) = [0; 3; 8];
x(:,2,1) = [20; 5; -4];
x(:,3,1) = [-15; 8; 9];
x(:,4,1) = [8; 3; 15];        % agent 4

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
            x_hat(:,i,k) = x(:,i,k); % use true value if insufficient history
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

%% Plot States
%% Plot States - Draw each dimension in separate figures
%titles = {'x_{i1}', 'x_{i2}', 'x_{i3}'};
% for dim = 1:3
%     figure;
%     for i = 1:N
%         plot(squeeze(x(dim,i,:)), 'DisplayName', sprintf('x_{%d%d}', i, dim)); hold on;
%     end
%     %title(titles{dim});
%     xlabel('Steps');
%     ylabel(titles{dim});
%     legend;
% end

figure;
for i = 1:N
    plot(squeeze(x(1,i,:)), 'DisplayName', sprintf('x_{%d%d}', i, 1)); hold on;
end
%title(titles{dim});
xlabel('Steps');
ylabel('$x_i$','Interpreter','latex');
xlim([0, 300]); 
legend('Agent 1','Agent 2','Agent 3','Agent 4');

figure;
for i = 1:N
    plot(squeeze(x(2,i,:)), 'DisplayName', sprintf('x_{%d%d}', i, 2)); hold on;
end
%title(titles{dim});
xlabel('Steps');
ylabel('$\dot{x_i}$','Interpreter','latex');
xlim([0, 300]); 
legend('Agent 1','Agent 2','Agent 3','Agent 4');

figure;
for i = 1:N
    plot(squeeze(x(3,i,:)), 'DisplayName', sprintf('x_{%d%d}', i, 3)); hold on;
end
%title(titles{dim});
xlabel('Steps');
ylabel('$\ddot{x_i}$','Interpreter','latex');
xlim([0, 300]); 
legend('Agent 1','Agent 2','Agent 3','Agent 4');

%% Plot Control Inputs
figure;
for i = 1:N
    plot(u(i,:), 'DisplayName', sprintf('u_{%d}', i)); hold on;
end
legend('Agent 1','Agent 2','Agent 3','Agent 4'); 
%title('Control Inputs'); 
xlabel('Steps'); 
ylabel('$u_i$','Interpreter','latex');


%% Compute Consensus Error ||Lx||_2
Lx = zeros(Kmax+1, N);
Lx_norm = zeros(1, Kmax+1);

for k = 1:Kmax+1
    x_pos = squeeze(x(1,:,k))';  % 仅使用位置维�?x1
    Lx(k,:) = L * x_pos;
    Lx_norm(k) = norm(Lx(k,:), 2);  % 计算二范�?
end

%% Plot Consensus Error ||Lx||_2
figure;
plot(0:Kmax, Lx_norm, 'LineWidth', 1.5);
xlabel('Step k'); ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
%title('Consensus Error Evolution: $\|Lx\|_2$', 'Interpreter', 'latex');
grid on;
