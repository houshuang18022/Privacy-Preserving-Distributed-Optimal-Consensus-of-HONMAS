clear; close all; clc;

% 文件与图例对应关系（按层次调整后的顺序）
files = {
    'lx_mywork_1.mat'         % 4nodes_ourwork_algorithm1
    'lx2_mywork_2.mat'        % 4nodes_ourwork_algorithm2
    'lx2_sensor.mat'          % 4nodes_Tan et al. (2022)
    % 'lx2_nodes10_1.mat'       % 10nodes_ourwork_algorithm1
    % 'lx2_nodes10_2.mat'       % 10nodes_ourwork_algorithm2
};

legends_text = {
    '4node - Algorithm1'
    '4nodes - Algorithm2'
    '4nodes - Tan et al. (2022)'
    % '10nodes\_ourwork\_algorithm1'
    % '10nodes\_ourwork\_algorithm2'
};

% 使用五种高区分度颜色
colors = [
    0.00 0.45 0.74;  % 蓝 blue
    0.85 0.33 0.10;  % 橙 orange
    0.93 0.69 0.13;  % 黄 yellow
    % 0.49 0.18 0.56;  % 紫 purple
    % 0.47 0.67 0.19;  % 绿 green
];

% 五种不同线型
linestyles = {'-', '--', '-.'};

figure;
hold on;

% 绘制主图
for i = 1:numel(files)
    dataStruct = load(files{i});
    fieldNames = fieldnames(dataStruct);
    y = dataStruct.(fieldNames{1});
    y = y(:);
    steps = 1:length(y);

    plot(steps, y, ...
        'LineWidth', 1.8, ...
        'Color', colors(i, :), ...
        'LineStyle', linestyles{i}, ...
        'DisplayName', legends_text{i});
end

xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
%title('Comparison of Different Algorithms under 4-node and 10-node Systems', 'FontSize', 13);
legend('Location', 'best', 'FontSize', 10);
xlim([0,300])
grid on;

% ===============================
% 添加放大子图 (Zoom-in Inset)
% ===============================
axes('Position', [0.58 0.55 0.3 0.3]); % 子图位置 [left bottom width height]
box on; hold on;

xrange = [296 300];
yrange = [0 0.25];

for i = 1:numel(files)
    dataStruct = load(files{i});
    fieldNames = fieldnames(dataStruct);
    y = dataStruct.(fieldNames{1});
    y = y(:);
    steps = 1:length(y);

    plot(steps, y, ...
        'LineWidth', 1.2, ...
        'Color', colors(i, :), ...
        'LineStyle', linestyles{i});
end

xlim(xrange);
ylim(yrange);
grid on;
% title('Zoom-in View', 'FontSize', 10);
set(gca, 'FontSize', 9);

% ===============================
% 添加矩形标注 (显示放大区域)
% ===============================
annotation('rectangle', [0.29, 0.21, 0.16, 0.18], 'Color', 'k', 'LineWidth', 1);
 annotation('arrow', [0.45 0.58], [0.4 0.68], 'Color', 'k'); % 连接主图与子图

hold off;
