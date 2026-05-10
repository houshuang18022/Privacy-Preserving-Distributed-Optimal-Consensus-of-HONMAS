clear all;
close all;
clc;

%% 参数设置
N = 4;              % 智能体数�?
sigma = 3;          % 系统阶数
T =2;            % 控制参数
steps = 300;      % 仿真步数
dt = 0.6;         % 步长

Q = 10^5;
% 通信拓扑�?(邻接矩阵)
A = [0 1 0 0;
     0 0 1 1;
     0 1 0 1;
     0 1 1 0];
 
% 控制参数
alpha1 = 0.0402;
alpha2 = 0.0079;
beta1 = 3.3333;
beta2 = 2.5000;

% 状�?变量初始�?
x = zeros(steps, N);    % 位置
v = zeros(steps, N);    % �?��导（速度�?
a = zeros(steps, N);    % 二阶导（加�?度）
u = zeros(steps, N);    % 控制输入

% 辅助系统状�?初始�?
omega_hat = zeros(N, sigma);  % 对应的估计项 omega_i
b_hat = zeros(N, sigma);      % 对应的估计项 b_i
s = zeros(N, 1);              % 滑模面状�?

% 初始�?
x(1,:) = [0, 20, -15, 8];
v(1,:) = [3, 5, 8, 3]; 
a(1,:) = [8, -4, 9, 15];
u(1,:) = [0, 0, 0, 0];

% 设置增益矩阵
K1 = 20 * eye(N);    % 适当的增益矩�?K1
K2 = 10 * eye(N);     % 适当的增益矩�?K2
gamma = 1;           % 滑模控制的参�?

P(N) = PaillierCrypto(128); % create an instance of PaillierCrypto class
for i = 1:N
    P(i).generateKeys();
    PK(i) = P(i).getPublicKey.n2;
end  
%% 主循�?
for ind= 1:steps-1
    states = [x(ind,:), v(ind,:),a(ind,:)];

    for i=1:N
        ranP(i) = P(1).bi((round((0.01 + 0.98 * rand) * 100))); %生成�?��随机�?
    end

    for i = 1:3*N
        if(states(i)>=0)%如果当前状�?�?states(i) 是正数或�?
            state_bi(i) = P(1).bi(uint64(round(states(i) * Q))); 
            neg_state_bi(i) = P(1).bi(uint64(2^64 - round(states(i) * Q)));%补码表示负数
        else
            state_bi(i) = P(1).bi(uint64(2^64 - round(-states(i) * Q)));
            neg_state_bi(i) = P(1).bi(uint64(round(-states(i) * Q)));
        end
    end

    x_difference = zeros(4,1);  %x_difference(i)计算agent i与所有邻居的加权x状�?差的�?
    v_difference = zeros(4,1); %v_difference(i)计算agent i与所有邻居的加权v状�?差的�?
    a_difference = zeros(4,1); %hatmu_difference(i)计算agent i与所有邻居的加权hatmu状�?差的�?

    for i = 1:N
        for j = 1:N
            if A(i, j) == 1  % 如果节点 i 和节�?j 有连�?
                    state_en1 = P(i).encrypt(state_bi(i)); 
                    neg_state_en2 = P(i).encrypt(neg_state_bi(j));
                    x_difference(i) = x_difference(i) + ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue())/(Q*100*100);
            end
        end
    end
    for i=1:N
        for j=1:N
            if A(i,j)==1
                     state_en1 = P(i).encrypt(state_bi(4+i)); 
                     neg_state_en2 = P(i).encrypt(neg_state_bi(4+j));
                     v_difference(i) = v_difference(i) + ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue())/(Q*100*100);
            end
        end
    end
    for i=1:N
        for j=1:N
            if A(i,j)==1
                     state_en1 = P(i).encrypt(state_bi(8+i)); 
                     neg_state_en2 = P(i).encrypt(neg_state_bi(8+j));
                     a_difference(i) = a_difference(i) + ranP(i).intValue() * (P(i).decrypt(state_en1.multiply(neg_state_en2).modPow(ranP(j), PK(i))).intValue())/(Q*100*100);                
            end
        end
    end
    disp(ind);

     for i = 1:N
         xi = x(ind, i);
         vi = v(ind, i);
         ai = a(ind, i);
        fi = 0;
        gi = 1;

        
             % 控制输入计算
        ui = ( - (T^2 / 12) * x_difference(i) ...
               - alpha1 * v_difference(i) ...
               - alpha2 *a_difference(i)...
               - fi ...
               - beta1 * v(ind,i) ...
               - beta2 * a(ind,i) ) / gi;
        u(ind, i) = ui;

        % 辅助系统的估计项更新
        s(i) = sum(x(ind, :) - x(ind, i));   % 滑模面状�?
        omega_hat(i, :) = omega_hat(i, :) - K1(i, i) * s(i) * sin(xi); % omega_i 更新
        b_hat(i, :) = b_hat(i, :) - K2(i, i) * s(i) * ui;  % b_i 更新

        a(ind+1, i) = a(ind, i) + dt * (fi + gi * ui);
        v(ind+1, i) = v(ind, i) + dt * a(ind, i);
        x(ind+1, i) = x(ind, i) + dt * v(ind, i);
     end

end

%% 绘图
time = (0:steps-1);

D = diag(sum(A, 2)); 
L = D - A;          
Lx = zeros(steps, N); % Lx
Lx_norm = zeros(1, steps); % \|Lx\|_2

for ind = 1:steps
    Lx(ind, :) = L * x(ind, :)'; 
    Lx_norm(ind) = norm(Lx(ind, :), 2); 
end

% Consistency Error Evolution
figure; 
plot(0:steps-1, Lx_norm, '-r', 'LineWidth', 1.5);
xlabel('Steps');
ylabel('$\|Lx\|_2$', 'Interpreter', 'latex');
savefig('our_work_Lx2.fig');


figure;
plot(time, x);
%title('x');
xlabel('Steps');
ylabel('$x_i$','Interpreter','latex');
legend('Agent 1','Agent 2','Agent 3','Agent 4');

figure;
plot(time, v);
%title('$\dot{x}$','Interpreter','latex');
xlabel('Steps');
ylabel('$\dot{x_i}$','Interpreter','latex');
legend('Agent 1','Agent 2','Agent 3','Agent 4');

figure;
plot(time, a);
%title('a');
xlabel('Steps');
ylabel('$\ddot{x_i}$','Interpreter','latex');
legend('Agent 1','Agent 2','Agent 3','Agent 4');

figure;
plot(time, u);
%title('u');
xlabel('Steps');
ylabel('$u_i$','Interpreter','latex');
legend('Agent 1','Agent 2','Agent 3','Agent 4');
