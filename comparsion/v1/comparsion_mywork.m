%% Load comparison data
load('lx2_mywork.mat');
Lx_norm1 = Lx_norm;
clear Lx_norm;

%% Load baseline data
load('lx2_sensor.mat');
Lx_norm2 = Lx_norm(1:300);
clear Lx_norm;

%% Plot comparison
x = 0:299;
figure;
plot(x, Lx_norm1, 'b', 'DisplayName', 'Our work');
hold on;
plot(x, Lx_norm2, 'r', 'DisplayName', 'Tan et al. (2022)');
hold off;

xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
legend('show');
grid on;
