# 新增外部基线（针对 E + DiffA）——获取与验证状态

日期：2026-10-24　状态：**已下载/已审计，未运行**

## 选定三个（按机制相关度 + 可获取性）

| # | 算法 | 年份/出处 | 机制对照点 | 获取状态 |
|---|---|---|---|---|
| 1 | **MENGWO** | 2025, Scientific Reports (open access) | DE 启发的变异算子 + EPD 重定位劣质个体 + 非线性种群缩减，与 DiffA 直接可比 | ✅ 论文全文已下载（含 Eq.12–15、NPSR 公式）；无官方代码 → 按公式复现 |
| 2 | **DE-Elimination GWO** | 2019, Scientific Reports (open access) | GWO 与 DE 进化操作 + 淘汰机制，差分思想在 GWO 的先例 | ✅ 论文全文已下载；无官方代码 → 按公式复现 |
| 3 | **Corrected GWO** | 2024, Applied Soft Computing（作者 FEX 源码） | 修正 GWO 更新方程（去 C、去 |D| 绝对值、current-to-prey），排除"经典 GWO 太弱"的解释 | ⚠️ 论文站被 captcha 拦截；FEX 页面已存（7.48 KB，机制描述完整）→ 按三条修正公式复现 |

## 未入选及原因

| 算法 | 原因 |
|---|---|
| MELGWO (2023, KBS) | 最相关，但 FEX 条目仅 4.67 KB 且**下载需 MathWorks 登录**（本机 IP 全域 403）；GitHub 镜像为空/垃圾仓。文献引用保留，暂不作数值基线 |
| MYIGWO (2025, AES) | GitHub 仅公开 1 个模块（`DualMutationScheme`，3812 B），非完整算法 → 不能作为可运行基线 |
| GWOCS (2018) | FEX 8.44 KB，同样受 403 限制；学术优先级低于上述三个 |
| MOGWO | 多目标算法，不能直接作单目标基线；仅用于相关工作讨论 |

## 文件位置

```
sparse_q/refs/MENGWO_2025/paper_fulltext.md          # 论文全文（含公式）
sparse_q/refs/DE_Elim_GWO_2019/paper_fulltext.md     # 论文全文（含公式）
sparse_q/refs/CorrectedGWO_2024/fex_page.md          # FEX 页面（机制描述、版本）
sparse_q/refs/MYIGWO_2025/differentiated_mutation_strategy.m  # 部分代码（仅存档，不作基线）
```

## 复现计划（下一步，尚未执行）

1. 按论文公式实现 `MENGWO_CEC.m`、`DEElimGWO_CEC.m`、`CorrectedGWO_CEC.m`，统一接口 `(f,state,[],N,seed)`。
2. **严格 FE 计费**：变异、交叉、EPD 重定位、种群缩减中的每次真实目标调用都计数。
3. 保留原论文参数：MENGWO k=0.25、b=1.5、q_ini/q_end；DE-Elim 的 DE 参数；Corrected GWO 的两个变体选较强的一个。
4. 先跑 8 函数 × 2 种子做**冒烟验证**（确认能跑、FE 精确、收敛曲线单调）。
5. 通过后进入正式 29 函数 × 30 种子（与 DAGWO 同种子配对）。
6. 保留 L-SHADE / jSO 作为非 GWO 强基线（已有结果，直接复用）。

## 审计要点

- MENGWO 的 Eq.12 与我们的 DiffA 结构相近（都在领导聚合上加差分项），是**最直接的对照**：若 DAGWO 优于 MENGWO，说明"独立差分槽位 + 已验证档案联合池 + 稀疏评价纪律"有价值。
- DE-Elimination 提供"差分思想已有先例"的文献支撑，用于相关工作。
- Corrected GWO 用来排除"收益只是来自 GWO 公式缺陷"。
