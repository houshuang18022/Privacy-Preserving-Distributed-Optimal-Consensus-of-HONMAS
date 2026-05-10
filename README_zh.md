# 高阶非线性多智能体系统隐私保护分布式最优一致性

[英文 / English Version](./README.md)

本仓库提供了基于 MATLAB 的高阶非线性多智能体系统分布式最优一致性实验代码，其中包含基于 Paillier 加密的隐私保护算法实现。

代码主要用于复现配套论文中的 Fig. 2、Fig. 3 和 Fig. 4 所对应的实验结果。

## 论文信息

- 论文题目：*Privacy-Preserving Distributed Optimal Consensus of High-Order Nonlinear Multi-Agent Systems*
- 论文链接：[IEEE Xplore](https://ieeexplore.ieee.org/document/11354804)
- 录用情况：该论文已被 IEEE TrustCom 接收。

## 仓库结构

- `consensus/`
  基础分布式最优一致性算法实现，对应 Fig. 2。

- `consensus_algorithm1/`
  带加密机制的隐私保护一致性算法，适用于 direct state difference 场景，对应 Fig. 3。

- `consensus_algorithm2/`
  带加密机制的隐私保护一致性算法，适用于 weighted state difference 场景，对应 Fig. 4。

- `comparsion/`
  用于方法对比的辅助脚本、图像和数据文件。目录名称保留项目原始拼写。

## 运行环境

- MATLAB

隐私保护相关实验目录内已经包含所需的 `PaillierCrypto.m` 文件。

## 快速复现

克隆仓库：

```bash
git clone https://github.com/houshuang18022/Privacy-Preserving-Distributed-Optimal-Consensus-of-HONMAS.git
cd Privacy-Preserving-Distributed-Optimal-Consensus-of-HONMAS
```

复现 Fig. 2：

```matlab
cd consensus
consensus
```

复现 Fig. 3：

```matlab
cd consensus_algorithm1
consensus_algorithm1
```

复现 Fig. 4：

```matlab
cd consensus_algorithm2
consensus_algorithm2
```

## 说明

- 仓库保留了原始实验目录结构和相关支撑文件。
- `comparsion/` 目录中包含实验对比过程使用或生成的中间脚本、图像和 `.mat` 数据文件。
- 如需进一步整理为正式开源项目，建议结合各 MATLAB 脚本中的参数配置和实验设置进行复核。

## 项目声明

- 项目名称：*Privacy-Preserving Distributed Optimal Consensus of High-Order Nonlinear Multi-Agent Systems*
- 作者：熊雨萱，张银炎
- 作者单位：College of Cyber Security, Jinan University
