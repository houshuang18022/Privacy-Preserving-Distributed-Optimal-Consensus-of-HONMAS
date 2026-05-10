clear all;
close all;
clc;

%% 参数设置
N = 10;              % 智能体数量
sigma = 3;           % 系统阶数
T = 2;               % 控制参数
steps = 300;         % 仿真步数
dt = 0.5;            % 步长
Q = 10^5;            % 放大系数

% 通信拓扑（环形网络）
A = [
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

% 控制参数
alpha1 = 0.0402;
alpha2 = 0.0079;
beta1 = 3.3333;
beta2 = 2.5000;

% 状态变量初始化
x = zeros(steps, N);
v = zeros(steps, N);
a = zeros(steps, N);
u = zeros(steps, N);

% 辅助系统变量
omega_hat = zeros(N, sigma);
b_hat = zeros(N, sigma);
s = zeros(N, 1);

% 初始状态（随机或指定）
x(1,:) = [0, 20, -15, 8, -10, 12, 25, -5, 18, -8];
v(1,:) = zeros(1, N);
a(1,:) = zeros(1, N);
u(1,:) = zeros(1, N);

% 增益矩阵
K1 = 10 * eye(N);
K2 = 5 * eye(N);
gamma = 1;

% Paillier 密钥生成（可选 512/1024-bit）
P(N) = PaillierCrypto(512);
for i = 1:N
    P(i).generateKeys();
    PK(i) = P(i).getPublicKey.n2;
end

total_t_start = tic;

%% 主循环
for ind = 1:steps-1

    % 状态向量拼接
    states = [x(ind,:), v(ind,:), a(ind,:)];

    % 随机加权参数
    for i = 1:N
        ranP(i) = P(1).bi((round((0.01 + 0.98 * rand) * 100)));
    end

    % 编码（正负号处理）
    for i = 1:3*N
        if states(i) >= 0
            state_bi(i) = P(1).bi(uint64(round(states(i) * Q))); 
            neg_state_bi(i) = P(1).bi(uint64(2^64 - round(states(i) * Q)));
        else
            state_bi(i) = P(1).bi(uint64(2^64 - round(-states(i) * Q)));
            neg_state_bi(i) = P(1).bi(uint64(round(-states(i) * Q)));
        end
    end

    % 初始化差分矩阵
    x_difference = zeros(N,1);
    v_difference = zeros(N,1);
    a_difference = zeros(N,1);

    % 加密状态差分计算 (x)
    for i = 1:N
        for j = 1:N
            if A(i,j) == 1
                state_en1 = P(i).encrypt(state_bi(i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(j));
                x_difference(i) = x_difference(i) + ...
                    ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2)...
                    .modPow(ranP(j), PK(i))).intValue()) / (Q*100*100);
            end
        end
    end

    % 加密状态差分计算 (v)
    for i = 1:N
        for j = 1:N
            if A(i,j) == 1
                state_en1 = P(i).encrypt(state_bi(N+i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(N+j));
                v_difference(i) = v_difference(i) + ...
                    ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2)...
                    .modPow(ranP(j), PK(i))).intValue()) / (Q*100*100);
            end
        end
    end

    % 加密状态差分计算 (a)
    for i = 1:N
        for j = 1:N
            if A(i,j) == 1
                state_en1 = P(i).encrypt(state_bi(2*N+i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(2*N+j));
                a_difference(i) = a_difference(i) + ...
                    ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2)...
                    .modPow(ranP(j), PK(i))).intValue()) / (Q*100*100);
            end
        end
    end

    disp(['Step ', num2str(ind), ' / ', num2str(steps-1)]);

    % 控制律更新
    for i = 1:N
        xi = x(ind,i);
        vi = v(ind,i);
        ai = a(ind,i);

        % 定义每个智能体的非线性动力学
        fi = (2 + 0.3*i) * sin(xi) + (mod(i,3)+1) * ai - 0.2 * vi;
        gi = 8 + mod(i,4);

        % 控制输入计算
        ui = ( - (T^2 / 12) * x_difference(i) ...
               - alpha1 * v_difference(i) ...
               - alpha2 * a_difference(i) ...
               - fi ...
               - beta1 * vi ...
               - beta2 * ai ) / gi;
        u(ind,i) = ui;

        % 辅助系统更新
        s(i) = sum(x(ind,:) - x(ind,i));
        omega_hat(i,:) = omega_hat(i,:) - K1(i,i) * s(i) * sin(xi);
        b_hat(i,:) = b_hat(i,:) - K2(i,i) * s(i) * ui;

        % 状态更新
        a(ind+1,i) = a(ind,i) + dt * (fi + gi * ui);
        v(ind+1,i) = v(ind,i) + dt * a(ind,i);
        x(ind+1,i) = x(ind,i) + dt * v(ind,i);
    end
end

% 耗时统计
total_elapsed = toc(total_t_start);
avg_time = total_elapsed / (steps - 1);
fprintf('平均每步耗时：%.6f 秒\n', avg_time);

%% 绘图
time = (0:steps-1);
D = diag(sum(A, 2));
L = D - A;
Lx = zeros(steps, N);
Lx_norm_1_nodes10 = zeros(1, steps);

for ind = 1:steps
    Lx(ind,:) = L * x(ind,:)';
    Lx_norm_1_nodes10(ind) = norm(Lx(ind,:), 2);
end

% 一致性误差
figure;
plot(0:steps-1, Lx_norm_1_nodes10, '-r', 'LineWidth', 1.5);
xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
title('Consensus Error Evolution');
savefig('our_work_Lx2_10nodes.fig');

% % 状态演化
% figure;
% plot(time, x, 'LineWidth', 1.2);
% xlabel('Steps'); ylabel('$x_i$', 'Interpreter', 'latex');
% title('Position $x_i$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
% 
% figure;
% plot(time, v, 'LineWidth', 1.2);
% xlabel('Steps'); ylabel('$\dot{x_i}$', 'Interpreter', 'latex');
% title('Velocity $\dot{x_i}$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
% 
% figure;
% plot(time, a, 'LineWidth', 1.2);
% xlabel('Steps'); ylabel('$\ddot{x_i}$', 'Interpreter', 'latex');
% title('Acceleration $\ddot{x_i}$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
% 
% figure;
% plot(time, u, 'LineWidth', 1.2);
% xlabel('Steps'); ylabel('$u_i$', 'Interpreter', 'latex');
% title('Control Input $u_i$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
