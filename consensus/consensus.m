clear all;
close all;
clc;

%% Parameters
N = 4;
sigma = 3;
T = 2;
steps = 100;
dt = 0.5;

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

%% Main simulation loop
for t = 1:steps-1
    for i = 1:N
        neighbors = find(A(i, :) == 1);
        xi = x(t, i);
        vi = v(t, i);
        ai = a(t, i);

        sum_x = 0;
        sum_v = 0;
        sum_a = 0;

        for k = neighbors
            sum_x = sum_x + (xi - x(t, k));
            sum_v = sum_v + (vi - v(t, k));
            sum_a = sum_a + (ai - a(t, k));
        end

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

        ui = ( - (T^2 / 12) * sum_x ...
               - alpha1 * sum_v ...
               - alpha2 * sum_a ...
               - fi ...
               - beta1 * vi ...
               - beta2 * ai ) / gi;
        u(t, i) = ui;

        a(t+1, i) = a(t, i) + dt * (fi + gi * ui);
        v(t+1, i) = v(t, i) + dt * a(t, i);
        x(t+1, i) = x(t, i) + dt * v(t, i);
    end
end

%% Plots
time = 0:steps-1;

figure;
plot(time, x);
title('x');
xlabel('Time (s)');
ylabel('x_i');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');

figure;
plot(time, v);
title('v');
xlabel('Time (s)');
ylabel('v_i');

figure;
plot(time, a);
title('a');
xlabel('Time (s)');
ylabel('a_i');

figure;
plot(time, u);
title('u');
xlabel('Time (s)');
ylabel('u_i');
legend('Agent 1', 'Agent 2', 'Agent 3', 'Agent 4');
