clear all;
close all;
clc;

%% Parameters
N = 10;
sigma = 3;
T = 2;
steps = 300;
dt = 0.5;
Q = 10^5;

%% Communication topology
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

%% Control parameters
alpha1 = 0.0402;
alpha2 = 0.0079;
beta1 = 3.3333;
beta2 = 2.5000;

%% State initialization
x = zeros(steps, N);
v = zeros(steps, N);
a = zeros(steps, N);
u = zeros(steps, N);

%% Initial conditions
x(1,:) = [0, 20, -15, 8, -10, 12, 25, -5, 18, -8];
v(1,:) = zeros(1, N);
a(1,:) = zeros(1, N);
u(1,:) = zeros(1, N);

%% Paillier setup
P(N) = PaillierCrypto(512);
for i = 1:N
    P(i).generateKeys();
    PK(i) = P(i).getPublicKey.n2;
end

encrypted_delta = zeros(steps-1, N);
total_t_start = tic;

%% Main simulation loop
for ind = 1:steps-1
    for i = 1:N
        ranP(i) = P(1).bi(round((0.01 + 0.98 * rand) * 100));
    end

    delta = zeros(N, 1);
    for i = 1:N
        delta(i) = (T^2 / 12) * x(ind, i) + alpha1 * v(ind, i) + alpha2 * a(ind, i);
    end

    for i = 1:N
        encrypted_delta(ind, i) = P(i).encrypt(P(i).bi(round(delta(i) * Q))).doubleValue();
    end

    for i = 1:N
        if delta(i) >= 0
            delta_bi(i) = P(1).bi(uint64(round(delta(i) * Q)));
            neg_delta_bi(i) = P(1).bi(uint64(2^64 - round(delta(i) * Q)));
        else
            delta_bi(i) = P(1).bi(uint64(2^64 - round(-delta(i) * Q)));
            neg_delta_bi(i) = P(1).bi(uint64(round(-delta(i) * Q)));
        end
    end

    difference = zeros(N,1);
    for i = 1:N
        for j = 1:N
            if A(i, j) == 1
                state_en1 = P(i).encrypt(delta_bi(i));
                neg_state_en2 = P(i).encrypt(neg_delta_bi(j));
                difference(i) = difference(i) + ...
                    ranP(i).intValue() * ...
                    P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue() / ...
                    (Q * 100 * 100);
            end
        end
    end

    for i = 1:N
        xi = x(ind, i);
        vi = v(ind, i);
        ai = a(ind, i);

        fi = (2 + 0.3 * i) * sin(xi) + (mod(i, 3) + 1) * ai - 0.3 * vi;
        gi = 8 + mod(i, 4);

        ui = (-difference(i) - fi - beta1 * v(ind, i) - beta2 * a(ind, i)) / gi;
        u(ind, i) = ui;

        a(ind+1, i) = a(ind, i) + dt * (fi + gi * ui);
        v(ind+1, i) = v(ind, i) + dt * a(ind, i);
        x(ind+1, i) = x(ind, i) + dt * v(ind, i);
    end

    disp(['Step ', num2str(ind), ' / ', num2str(steps - 1)]);
end

total_elapsed = toc(total_t_start);
avg_time = total_elapsed / (steps - 1);
fprintf('Average runtime per step: %.6f s\n', avg_time);

%% Plots
time = 0:steps-1;
D = diag(sum(A, 2));
L = D - A;
Lx = zeros(steps, N);
Lx_norm_2_nodes10 = zeros(1, steps);

for ind = 1:steps
    Lx(ind, :) = L * x(ind, :)';
    Lx_norm_2_nodes10(ind) = norm(Lx(ind, :), 2);
end

figure;
plot(0:steps-1, Lx_norm_2_nodes10, '-r', 'LineWidth', 1.5);
xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
title('Consensus Error Evolution');
savefig('Lx_norm.fig');
%
% figure;
% plot(time, x, 'LineWidth', 1.3);
% xlabel('Steps'); ylabel('$x_i$', 'Interpreter', 'latex');
% title('Position $x_i$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
%
% figure;
% plot(time, v, 'LineWidth', 1.3);
% xlabel('Steps'); ylabel('$\dot{x_i}$', 'Interpreter', 'latex');
% title('Velocity $\dot{x_i}$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
%
% figure;
% plot(time, a, 'LineWidth', 1.3);
% xlabel('Steps'); ylabel('$\ddot{x_i}$', 'Interpreter', 'latex');
% title('Acceleration $\ddot{x_i}$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
%
% figure;
% plot(time, u, 'LineWidth', 1.3);
% xlabel('Steps'); ylabel('$u_i$', 'Interpreter', 'latex');
% title('Control Input $u_i$ Evolution');
% legend(arrayfun(@(i) sprintf('Agent %d', i), 1:N, 'UniformOutput', false));
