# 16 — CLPSO 严格复现审计（TEC2006 原版代码包，2026-10-17）

范围：按用户要求，用**作者原版代码**严格复现 CLPSO，替换此前从冻结归档复用的
CLPSO 结果。**不修改 VAST-GWO 与其它臂。**

## 0. 来源

| 项 | 值 |
|---|---|
| 论文 | Liang, Qin, Suganthan & Baskar, "Comprehensive Learning Particle Swarm Optimizer for Global Optimization of Multimodal Functions", IEEE Trans. Evol. Comput. 10(3), 2006 |
| 原版代码 | TEC2006 代码包 `CLPSO_new_func.m`（作者发布；镜像：`NTU-CCA/EE6227`@`Reference/Assignments/Assignment 1/TEC matlab code/`、`ldkong1205/ntu-graduate-courses` 同路径、`hmofrad/Adaptive-CPSO` TEC2006 目录） |
| 本移植 | `src/CLPSO_CEC.m`（sha256 前 16 位 `033b92eeea92ea3e`） |

## 1. 逐机制对应（与 `CLPSO_new_func.m` 一致）

* **Pc**：`t=0:1/(ps-1):1; t=5t; Pc_i = 0.5(exp(t_i)-1)/(exp(5)-1)`，范围 [0,0.5]。
* **速度系数**：`cc=[1.49445 1.49445]`；原版包中 `m=0` ⇒ `ai≡0`，即纯 pbest 示范学习
  （gbest 项存在但权重为 0，本移植保留该结构）。
* **逐维示范**：`fi1,fi2` 为每维随机粒子；`fi = fi1` 若 `pbestval(fi1)<pbestval(fi2)`，
  否则 `fi2`（并列取 fi2）；`bi(d)=1` 以概率 `Pc_i`；若全维未命中则随机强制一维为 1。
* **示范索引跨代保持**：`f_pbest` 仅在初始化与**刷新间隔触发**时重抽。
* **刷新间隔 = 5**：`stay_num(k)>=5` 时重置 `stay_num`、重抽 `fi/bi`、重建 `f_pbest`。
* **w**：线性 0.9 → 0.2（原版 `iwt`）。
* **速度限幅**：`mv=0.2*(ub-lb)`；速度初始化为 `U(-mv, mv)`。
* **越界处理**：新位置越界则**不评价、不回拉**（位置保留，等待速度把它带回域内）；
  这与常见"边界截断"变体不同，为原版行为。
* **pbest/停留计数**：`pbestval<=e` 记一次未改善（`stay_num+1`）。

## 2. 与实验框架的适配（仅接口与计费）

1. 初始位置由框架给定（同池协议）；速度按原版 `U(-mv,mv)` 初始化。
2. **FE 精确**：原版在内层粒子循环中不检查预算（最多可超支 ps−1 次），且以代数+FE
   双条件终止；本实现**逐次评价检查预算**，真实 FE 精确等于 100,000。
3. **w 调度**：原版按代数 `iwt(i)`；本实现在等 FE 协议下用 `w=0.9-0.7*(fe/budget)`。
4. 种群规模：按原论文 `N=40`（`algorithmPopulation('CLPSO')=40`）。
5. 移植陷阱记录：MATLAB 中列向量索引结果仍为列，`(D×1).*(1×D)` 会外积成 D×D；
   已在两处显式转置修正（纯移植问题，不影响算法语义）。该 bug 曾在首版烟测中被
   维度断言直接捕获。

## 3. 验证与预注册

* 烟测（`tests/test_clpso_smoke.m`）：FE=3000 精确、轨迹单调、T(end)==Best、确定性 PASS。
* 正式批：`clpso_*`（29 函数 × seeds 3001:3030 × D=50 × 100k，4 worker，可续跑
  `experiments/resume_clpso.m`）。
* 预注册：**CLPSO(2006) 进入主表**（替换归档 CLPSO）；归档数据保留、不再使用；
  该替换同样适用于"PSO 是否超过 CLPSO"的复核（新 PSO 为经典惯性权重版，
  与本 CLPSO 同协议同种子）。
