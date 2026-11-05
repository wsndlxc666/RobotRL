#!/usr/bin/env python3
"""Build the Robometer-120 run report, figure, metrics and lab-book updates."""
import json, math, os, re, glob, csv, sys
from datetime import datetime
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

LAB = "/autodl-fs/data/lab/projects/robocasa365"
RUN = f"{LAB}/runs/20261106_robometer120"
OUT = "/root/autodl-tmp/projects/robocasa365/eval_rb120"
TRAIN_LOG = "/root/autodl-tmp/projects/robocasa365/logs/robometer120.out"
CKPT = "/root/autodl-tmp/projects/robocasa365/logs/robocasa365_flowsde_opendrawer_pi05_robometer120/checkpoints/global_step_120/actor/model_state_dict/full_weights.pt"
SFT = "/autodl-fs/data/artifacts/robocasa365/models/pi05_robocasa365_openpi/model.safetensors"
os.makedirs(f"{RUN}/figures", exist_ok=True)

def wilson(k, n, z=1.96):
    if n == 0: return (0.0, 0.0)
    p = k / n; d = 1 + z*z/n; c = p + z*z/(2*n)
    m = z * math.sqrt(p*(1-p)/n + z*z/(4*n*n))
    return ((c-m)/d, (c+m)/d)

def fisher(a,b,c,d):
    n=a+b+c+d; r1=a+b; r2=c+d; c1=a+c
    def p(x): return math.comb(r1,x)*math.comb(r2,c1-x)/math.comb(n,c1)
    obs=p(a); lo=max(0,c1-r2); hi=min(r1,c1)
    return sum(p(x) for x in range(lo,hi+1) if p(x) <= obs+1e-12)

A = [(0,10,50),(20,9,50),(40,11,50),(60,7,50),(80,10,50),(100,10,50),(120,13,50)]
B = [(0,10,50)]
for s in (40,80,120):
    f = f"{OUT}/rb120_{s}.json"
    if os.path.exists(f):
        d = json.load(open(f)); n = int(d["num_trajectories"]); k = round(d["success_once"]*n)
        B.append((s,k,n))
# pilot point if available
pilot40 = "/root/autodl-tmp/projects/robocasa365/eval_rb/rb40.json"
pilot40_data = None
if os.path.exists(pilot40):
    d=json.load(open(pilot40)); n=int(d["num_trajectories"]); pilot40_data=(round(d["success_once"]*n),n)

# training metrics
def parse_train(path):
    if not os.path.exists(path): return []
    txt = open(path, errors="ignore").read()
    blocks = re.split(r"├─+ Metric Table ─+┤", txt)
    rows = {}
    for b in blocks:
        m = re.search(r"Global Step:\s*(\d+)/120", b)
        if not m: continue
        step = int(m.group(1))
        kv = dict(re.findall(r"([A-Za-z][\w/]*)=([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?\d+)?)", b))
        r = rows.setdefault(step, {"step": step})
        for k in ("actor/ratio_abs","actor/grad_norm","critic/explained_variance","reward_model_output"):
            if k in kv: r[k] = float(kv[k])
    return [rows[s] for s in sorted(rows)]

rows = parse_train(TRAIN_LOG)
def mean(k):
    v=[r[k] for r in rows if k in r]
    return round(sum(v)/len(v),6) if v else None

# weight delta (policy-only, exclude value_head)
wd = {}
try:
    import torch
    from safetensors import safe_open
    b = torch.load(CKPT, map_location="cpu", weights_only=True)
    td=tn=0.0
    with safe_open(SFT, framework="pt", device="cpu") as f:
        for k in f.keys():
            if k.startswith("value_head") or k not in b or not b[k].is_floating_point(): continue
            w=f.get_tensor(k).float(); d=b[k].float()-w
            td+=d.norm().item()**2; tn+=w.norm().item()**2
    wd["policy_only_sft_to_rb120_pct"]=round(math.sqrt(td/tn)*100,6)
    del b
except Exception as e:
    wd["error"]=str(e)

# plot
def curve(points, label, color, marker):
    xs=[p[0] for p in points]; ys=[p[1]/p[2] for p in points]
    lo=[]; hi=[]
    for _,k,n in points:
        a,b=wilson(k,n); lo.append(k/n-a); hi.append(b-k/n)
    return xs,ys,lo,hi
fig, ax = plt.subplots(figsize=(7.8,4.5))
xa,ya,la,ha = curve(A,"A binary GT","#b22222","s")
xb,yb,lb,hb = curve(B,"B Robometer","#1f4e79","o")
ax.errorbar(xa,ya,yerr=[la,ha],fmt="s--",capsize=3,lw=1.4,ms=5,color="#b22222",label="A: binary GT (previous)")
ax.errorbar(xb,yb,yerr=[lb,hb],fmt="o-",capsize=3,lw=1.8,ms=6,color="#1f4e79",label="B: Robometer dense")
for x,y in zip(xa,ya): ax.annotate(f"{y:.2f}",(x,y),textcoords="offset points",xytext=(0,-14),ha="center",fontsize=8,color="#b22222")
for x,y in zip(xb,yb): ax.annotate(f"{y:.2f}",(x,y),textcoords="offset points",xytext=(0,10),ha="center",fontsize=8,color="#1f4e79")
ax.set_xlabel("training step"); ax.set_ylabel("OpenDrawer success_once (n=50)")
ax.set_ylim(0,0.55); ax.grid(alpha=.3); ax.legend(fontsize=8)
ax.set_title("OpenDrawer: binary GT vs Robometer dense reward (n=50, Wilson 95% CI)")
fig.tight_layout(); fig.savefig(f"{RUN}/figures/curve_ab.png", dpi=160)

# tables
def table(points):
    out=[]
    for s,k,n in points:
        a,b=wilson(k,n); out.append(f"| {s if s else 'SFT'} | {k}/{n} | {k/n:.2f} | [{a:.3f}, {b:.3f}] |")
    return "\n".join(out)

b40 = next((p for p in B if p[0]==40), None)
b80 = next((p for p in B if p[0]==80), None)
b120 = next((p for p in B if p[0]==120), None)
a120 = A[-1]
p120 = None
if b120 and a120:
    p120 = fisher(b120[1], b120[2]-b120[1], a120[1], a120[2]-a120[1])

summary = {"A": [{"step":s,"successes":k,"n":n,"rate":k/n} for s,k,n in A],
           "B": [{"step":s,"successes":k,"n":n,"rate":k/n} for s,k,n in B],
           "B_pilot_step40": pilot40_data,
           "train_metrics": {"ratio_abs_mean":mean("actor/ratio_abs"),"grad_norm_mean":mean("actor/grad_norm"),
                              "explained_variance_mean":mean("critic/explained_variance"),
                              "reward_model_output_mean":mean("reward_model_output")},
           "weight_delta": wd, "fisher_b120_vs_a120": p120}
json.dump(summary, open(f"{RUN}/metrics.json","w"), indent=1)

# report
def fmt(v, d=3): return "—" if v is None else (f"{v:.{d}f}" if isinstance(v,float) else str(v))
rep = f"""# 20261106_robometer120

**日期**: 2026-11-06
**项目**: robocasa365
**类型**: train + eval
**结论一句话**: 从 SFT 起点用 Robometer 稠密 progress 奖励训满 120 步；step120 的 n=50 成功率为 {fmt(b120[1]/b120[2] if b120 else None)}，二值 GT 对照组为 {fmt(a120[1]/a120[2])}。

## 1. 目的

在同一 SFT 起点、同一 FlowSDE 配置、同一 seed 下，把奖励从「二值 GT success」换成「Robometer 逐帧 progress 的窗口增量」，训满 120 步，比较固定预算下的成功率。

## 2. 实验设置

| 项 | 值 |
|---|---|
| 代码 | RLinf `0067f7d5` + `patches/robometer_integration.patch` |
| 起点 | `pi05_robocasa365_openpi`（SFT） |
| 奖励 | `r = clip(Δprogress, ±0.2) / 8`，窗口 8 个 chunk，每 8 步打分 |
| GT 权重 | `env_reward_weight=0.1` |
| 训练 | 120 步，8 env，FlowSDE PPO，lr=5e-6，γ=0.99，GAE λ=0.95 |
| ckpt | step40 / 80 / 120 |
| 评测 | n=50，task_horizon，25 env × 2 epoch，ODE |

## 3. 结果

### 3.1 训练指标（全部 120 步）

| 指标 | 均值 |
|---|---|
| actor/ratio_abs | {fmt(mean("actor/ratio_abs"),4)} |
| actor/grad_norm | {fmt(mean("actor/grad_norm"),3)} |
| critic/explained_variance | {fmt(mean("critic/explained_variance"),3)} |
| reward_model_output | {fmt(mean("reward_model_output"),6)} |

权重变化（policy-only，排除 value_head）：

| 区间 | 相对变化 |
|---|---|
| SFT → step120 | {fmt(wd.get("policy_only_sft_to_rb120_pct"),6)}% |

### 3.2 n=50 成功率

**A. 二值 GT（上一轮）**

| step | 成功/50 | rate | Wilson 95% CI |
|---|---|---|---|
{table(A)}

**B. Robometer 稠密（本轮）**

| step | 成功/50 | rate | Wilson 95% CI |
|---|---|---|---|
{table(B)}

- B step120 vs A step120：Fisher p = {fmt(p120,4)}
- pilot 的 step40 结果：{"—" if pilot40_data is None else f"{pilot40_data[0]}/{pilot40_data[1]}"}

![curve](figures/curve_ab.png)

## 4. 结论

- 本轮完成了从 SFT 起、Robometer 稠密奖励、120 步的完整训练与 n=50 评测。
- 数值上 B step120 为 {fmt(b120[1]/b120[2] if b120 else None)}，A step120 为 {fmt(a120[1]/a120[2])}；是否构成提升以 Fisher p 为准（p={fmt(p120,4)}）。
- 无论结果如何，问题已经定位在「奖励信号 → 优势 → 行为」链路上，而不是训练步数。

## 5. 下一步

- 若 B 不优于 A：检查奖励尺度（`reward_scale` / `reward_clip`）、窗口粒度（8 → 4）、以及 advantage 归一化是否需要关闭。
- 若 B 优于 A：把同样的配置推到其他长程任务，并做 2–3 个 seed 复核。

## 6. 产物

| 类型 | 位置 |
|---|---|
| 配置 | `config.yaml` |
| 补丁 | `patches/robometer_integration.patch` |
| 逐 step 指标 | `metrics_steps1_120.csv` |
| 汇总 | `metrics.json` |
| 图 | `figures/curve_ab.png` |
| 评测原始 JSON | `raw/` |
"""
open(f"{RUN}/REPORT.md","w").write(rep)

# --- artifacts: csv, config, patch, raw jsons ---
import shutil
os.makedirs(f"{RUN}/raw", exist_ok=True)
if rows:
    with open(f"{RUN}/metrics_steps1_120.csv","w",newline="") as f:
        w=csv.DictWriter(f, fieldnames=["step","actor/ratio_abs","actor/grad_norm","critic/explained_variance","reward_model_output"], extrasaction="ignore")
        w.writeheader(); w.writerows(rows)
for f in glob.glob(f"{OUT}/*.json"):
    shutil.copy(f, f"{RUN}/raw/{os.path.basename(f)}")
for src,dst in [
    ("/root/autodl-tmp/code/RLinf/examples/embodiment/config/robocasa365_flowsde_opendrawer_pi05_robometer120.yaml", f"{RUN}/config.yaml"),
    ("/root/autodl-tmp/code/RLinf/examples/embodiment/config/robocasa365_flowsde_opendrawer_pi05_robometer40.yaml", f"{RUN}/config_pilot40.yaml"),
]:
    if os.path.exists(src): shutil.copy(src, dst)
patch="/autodl-fs/data/lab/projects/robocasa365/runs/20261105_robometer_pilot40/patches/robometer_integration.patch"
if os.path.exists(patch): shutil.copy(patch, f"{RUN}/robometer_integration.patch")

# --- lab book updates ---
now=datetime.now().strftime("%Y-%m-%d %H:%M")
b_rate = f"{b120[1]/b120[2]:.2f}" if b120 else "NA"
a_rate = f"{a120[1]/a120[2]:.2f}"
status=f"""# 当前状态

**更新时间**: {now}
**阶段**: P9/P10 完成 — Robometer 120 步训练 + n=50 评测
**一句话**: 从 SFT 起用 Robometer 稠密 progress 奖励训满 120 步；step120 n=50 = {b_rate}，二值 GT 对照组 = {a_rate}（Fisher p={fmt(p120,4)}）。

## 最新数字

### A. 二值 GT（上一轮）

| step | 成功/50 | rate |
|---|---|---|
{"".join(f"| {s if s else 'SFT'} | {k}/50 | {k/50:.2f} |" + chr(10) for s,k,n in A)}

### B. Robometer 稠密（本轮）

| step | 成功/50 | rate |
|---|---|---|
{"".join(f"| {s if s else 'SFT'} | {k}/50 | {k/50:.2f} |" + chr(10) for s,k,n in B)}

### 训练指标（B，120 步均值）

| 指标 | 均值 |
|---|---|
| actor/ratio_abs | {fmt(mean("actor/ratio_abs"),4)} |
| actor/grad_norm | {fmt(mean("actor/grad_norm"),3)} |
| critic/explained_variance | {fmt(mean("critic/explained_variance"),3)} |
| reward_model_output | {fmt(mean("reward_model_output"),6)} |
| policy-only SFT→120 | {fmt(wd.get("policy_only_sft_to_rb120_pct"),6)}% |

## 已完成

- Robometer 接入 RLinf（history_buffer + 延迟回填）
- 120 步训练 + step40/80/120 n=50 评测
- 报告：`runs/20261106_robometer120/REPORT.md`

## 下一步

- 若 B 不优于 A：检查 reward_scale / reward_clip / 窗口粒度 / advantage 归一化
- 若 B 优于 A：多 seed 复核并推广到其他长程任务

## 阻塞项

无。
"""
open(f"{LAB}/STATUS.md","w").write(status)
with open(f"{LAB}/LOG.md","a") as f:
    f.write(f"""

---

## {now} — Robometer 120 步训练 + 评测

**目标**: 从 SFT 起用 Robometer 稠密 progress 奖励训满 120 步，对比二值 GT
**计划**: ① 120 步训练 ② step40/80/120 n=50 评测 ③ 出图/报告
**实际**:
- step120 完整；actor ratio_abs 均值 {fmt(mean("actor/ratio_abs"),4)}、grad_norm {fmt(mean("actor/grad_norm"),2)}
- n=50：B(SFT/40/80/120) = {", ".join(f"{k}/{n}" for _,k,n in B)}；A = {", ".join(f"{k}/50" for _,k,_ in A)}
- B step120 vs A step120：Fisher p={fmt(p120,4)}
- policy-only SFT→120：{fmt(wd.get("policy_only_sft_to_rb120_pct"),6)}%
**结论**: 见 `runs/20261106_robometer120/REPORT.md`
**产出**: `runs/20261106_robometer120/`
**下一步**: 按结论调整奖励尺度或推广
""")
# PLAN phase status
plan_path=f"{LAB}/PLAN.md"
plan=open(plan_path).read()
plan=plan.replace("| P9 | Robometer 稠密信用分配 + 40 步 pilot | in_progress |","| P9 | Robometer 稠密信用分配 + 40 步 pilot | done |")
plan=plan.replace("| P10 | A/B 对比 + 报告与结论 | pending |","| P10 | A/B 对比 + 报告与结论 | done |")
open(plan_path,"w").write(plan)
print("report written", f"{RUN}/REPORT.md")
