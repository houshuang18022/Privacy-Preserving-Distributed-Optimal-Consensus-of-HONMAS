
% 加载第一个文件（假设变量名是 Lx_norm）
load('lx2_mywork.mat');  
Lx_norm1 = Lx_norm;  % 存储到新变量，避免覆盖
clear Lx_norm;  % 清除原变量，避免冲突

% 加载第二个文件
load('lx2_sensor.mat'); 
Lx_norm2 = Lx_norm(1:300);  % 截断前 300 个点
clear Lx_norm;

% 绘制图形
x = 0:299;  % x 轴（0~299）
figure;
plot(x, Lx_norm1, 'b', 'DisplayName', 'Our work');
hold on;
plot(x, Lx_norm2, 'r', 'DisplayName', 'Tan et.al(2022）');
hold off;

xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
%title('两个 Lx\_norm 矩阵的比较');
legend('show');
grid on;