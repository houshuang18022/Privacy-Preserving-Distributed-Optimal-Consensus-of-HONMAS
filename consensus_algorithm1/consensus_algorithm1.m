clear all;
close all;
clc;

%% Parameters
N = 4;
sigma = 3;
T = 2;
steps = 300;
dt = 0.5;
Q = 10^5;

%% Communication topology
A = [0 1 0 0;
     0 0 1 1;
     0 1 0 1;
     0 1 1 0];

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

%% Auxiliary states
omega_hat = zeros(N, sigma);
b_hat = zeros(N, sigma);
s = zeros(N, 1);

%% Initial conditions
x(1,:) = [0, 20, -15, 8];
v(1,:) = [0, 0, 0, 0];
a(1,:) = [0, 0, 0, 0];
u(1,:) = [0, 0, 0, 0];

%% Gain matrices
K1 = 10 * eye(N);
K2 = 5 * eye(N);
gamma = 1;

%% Paillier setup
P(N) = PaillierCrypto(1024);
for i = 1:N
    P(i).generateKeys();
    PK(i) = P(i).getPublicKey.n2;
end

total_t_start = tic;

%% Main simulation loop
for ind = 1:steps-1
    states = [x(ind,:), v(ind,:), a(ind,:)];

    % Generate random masking coefficients.
    for i = 1:N
        ranP(i) = P(1).bi(round((0.01 + 0.98 * rand) * 100));
    end

    % Encode signed states using fixed-point scaling.
    for i = 1:3*N
        if states(i) >= 0
            state_bi(i) = P(1).bi(uint64(round(states(i) * Q)));
            neg_state_bi(i) = P(1).bi(uint64(2^64 - round(states(i) * Q)));
        else
            state_bi(i) = P(1).bi(uint64(2^64 - round(-states(i) * Q)));
            neg_state_bi(i) = P(1).bi(uint64(round(-states(i) * Q)));
        end
    end

    x_difference = zeros(4,1);
    v_difference = zeros(4,1);
    a_difference = zeros(4,1);

    % Compute encrypted neighbor-state differences.
    for i = 1:N
        for j = 1:N
            if A(i, j) == 1
                state_en1 = P(i).encrypt(state_bi(i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(j));
                x_difference(i) = x_difference(i) + ...
                    ranP(i).intValue() * ...
                    P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue() / ...
                    (Q * 100 * 100);
            end
        end
    end

    for i = 1:N
        for j = 1:N
            if A(i, j) == 1
                state_en1 = P(i).encrypt(state_bi(4 + i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(4 + j));
                v_difference(i) = v_difference(i) + ...
                    ranP(i).intValue() * ...
                    P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue() / ...
                    (Q * 100 * 100);
            end
        end
    end

    for i = 1:N
        for j = 1:N
            if A(i, j) == 1
                state_en1 = P(i).encrypt(state_bi(8 + i));
                neg_state_en2 = P(i).encrypt(neg_state_bi(8 + j));
                a_difference(i) = a_difference(i) + ...
                    ranP(i).intValue() * ...
                    P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue() / ...
                    (Q * 100 * 100);
            end
        end
    end

    disp(ind);

    for i = 1:N
        xi = x(ind, i);
        vi = v(ind, i);
        ai = a(ind, i);

        switch i
            case 1
                fi = 3 * xi * sin(xi) + 8 * ai;
                gi = 10;
            case 2
                fi = 8 * cos(vi) * xi - 3 * ai;
                gi = 12;
            case 3
                fi = 2 * xi * ai - 2 * vi + 4 * sin(ai);
                gi = 7;
            case 4
                fi = 2 * sin(xi);
                gi = 9;
        end

        ui = ( - (T^2 / 12) * x_difference(i) ...
               - alpha1 * v_difference(i) ...
               - alpha2 * a_difference(i) ...
               - fi ...
               - beta1 * v(ind, i) ...
               - beta2 * a(ind, i) ) / gi;
        u(ind, i) = ui;

        s(i) = sum(x(ind, :) - x(ind, i));
        omega_hat(i, :) = omega_hat(i, :) - K1(i, i) * s(i) * sin(xi);
        b_hat(i, :) = b_hat(i, :) - K2(i, i) * s(i) * ui;

        a(ind+1, i) = a(ind, i) + dt * (fi + gi * ui);
        v(ind+1, i) = v(ind, i) + dt * a(ind, i);
        x(ind+1, i) = x(ind, i) + dt * v(ind, i);
    end
end

total_elapsed = toc(total_t_start);
avg_time = total_elapsed / (steps - 1);
fprintf('Average runtime per step: %.6f s\n', avg_time);

%% Plots
time = 0:steps-1;

D = diag(sum(A, 2));
L = D - A;
Lx = zeros(steps, N);
Lx_norm = zeros(1, steps);

for ind = 1:steps
    Lx(ind, :) = L * x(ind, :)';
    Lx_norm(ind) = norm(Lx(ind, :), 2);
end

figure;
plot(0:steps-1, Lx_norm, '-r', 'LineWidth', 1.5);
xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
savefig('our_work_Lx2.fig');

figure;
plot(time, x);
xlabel('Steps');
ylabel('$x_i$', 'Interpreter', 'latex');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');

figure;
plot(time, v);
xlabel('Steps');
ylabel('$\dot{x_i}$', 'Interpreter', 'latex');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');

figure;
plot(time, a);
xlabel('Steps');
ylabel('$\ddot{x_i}$', 'Interpreter', 'latex');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');

figure;
plot(time, u);
xlabel('Steps');
ylabel('$u_i$', 'Interpreter', 'latex');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');
