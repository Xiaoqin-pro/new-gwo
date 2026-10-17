# 参考源码上传说明（供复现核对）

| 目录 | 来源 | 版本 | 说明 |
|---|---|---|---|
| `RL-LGWO/` | https://github.com/mroayaei/RL-LGWO | commit `1a004c4296ebdabc9c50d7bbf9bd4b2f1852a0a5` | 作者 Python 源码（含 LICENSE）。已排除 `.git/` 与 `cec2017/`（内含 23.5MB `data.pkl` 基准数据，可用 `pip install cec2017` 或原仓库获取）。 |
| `DMSGWO/` | https://github.com/wangyoki/DMSGWO | commit `a6229f5e8254d9a340e8de3774c88be8f22b89cb` | 官方 MATLAB 文件 `dmsgwo`（无扩展名）+ 空 README。**官方开发组循环为空**（第 72–76 行仅剩 `%%` 占位）——见下。 |
| `MELGWO/` | FEX 403 / 无公开代码 | – | 无源码可用，仅文献记录（`docs/11_RECENT_BASELINES.md`）。 |

## 移植与修改（供核对）

* `../src/RLGWO_CEC.m`：按作者 Python 源码逐机制移植（RL 选择领导 + 探索项）。
  修改点：(1) 增加评价缓存，去除作者代码中的重复 objf 调用；(2) 严格真实 FE 计费
  （EvalProbe 探针校验）。标注为 "port"。
* `../src/DMSGWO_CEC.m`：官方仓库开发组更新为空循环，无法直接运行；
  按开放获取论文公式补全（φ=(f_i/f̄)³；w=0.5+0.5cos(πt/T)；X←(1−w)X+wX·φ）。
  标注为 "paper-repair implementation"。注意：其每代消耗 ~n1·D+n2 次真实评价，
  100k FE 下仅约 78 代，属作者设计，如实报告。
* 移植决策与屏幕计划详见 `../docs/11_RECENT_BASELINES.md`。

## 运行状态（重要）

两个移植版目前**只做过烟测**（可运行、FE 计费正确），**尚未跑正式对比**。
5 种子快检（`experiments/screen13_recent.m`）此前被暂缓，随时可启动。
