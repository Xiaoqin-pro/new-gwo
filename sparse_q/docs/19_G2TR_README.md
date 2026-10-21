# 拯救G2 / G2-TR Rescue Branch

本目录是从 `NEW_GWO_2026` 复制出来的独立 G2 救援开发区。源仓库已完成论文初稿，保持只读。

## 当前目标
检验能否用轻量信任域机制让 G2（alpha 邻域精化）在完整 VAST-GWO 中产生独立贡献，而不是被 E（精英档案）覆盖。

## P1 开发批
- 基准：CEC2017，D=50
- 函数：F1, F4, F6, F9, F11, F15, F21, F25
- 种子：3101–3110（未使用过）
- 预算：30,000 真实 FE
- 并行：MATLAB local 4 workers
- 臂：V1、A2(G1+E)、A4(G2 fixed-min)、G2-TR、G2-subset20
- 规模：5 × 8 × 10 = 400 runs
- 预注册：`sparse_q/docs/19_G2TR_PREREG.md`

## 运行
在 MATLAB 中：
```matlab
setup_project;
out = screen23_g2tr();
```

断点续跑：使用 `run_batch_sq` 的 `opt.resume`，不要改变 manifest。

## 边界
- 不修改、不过度读取最终测试指标作为调参信号。
- 不使用串行代替 4-worker。
- 不删除失败运行。
