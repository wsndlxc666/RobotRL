#!/usr/bin/env python
"""Extract RLinf TensorBoard scalars and plot reward / success curves."""
import argparse
import csv
import glob
import json
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def load_scalars(logdir):
    from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

    data = {}
    files = sorted(glob.glob(os.path.join(logdir, "**", "events.out.tfevents.*"), recursive=True))
    for f in files:
        ea = EventAccumulator(f, size_guidance={"scalars": 0})
        ea.Reload()
        for tag in ea.Tags().get("scalars", []):
            data.setdefault(tag, []).extend((e.step, e.value) for e in ea.Scalars(tag))
    for tag in data:
        data[tag].sort()
    return data


def series(data, tag):
    xs, ys = [], []
    for s, v in data.get(tag, []):
        xs.append(s)
        ys.append(v)
    return xs, ys


def smooth(ys, k):
    if k <= 1 or len(ys) < k:
        return ys
    out = []
    for i in range(len(ys)):
        lo = max(0, i - k + 1)
        out.append(sum(ys[lo : i + 1]) / (i - lo + 1))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--logdir", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--baseline", type=float, default=None)
    ap.add_argument("--baseline-trials", type=int, default=20)
    ap.add_argument("--task", default="CloseDrawer")
    ap.add_argument("--window", type=int, default=5)
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)
    data = load_scalars(args.logdir)
    print("tags:", sorted(data.keys()))

    # CSV dump
    with open(os.path.join(args.outdir, "metrics.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["tag", "step", "value"])
        for tag in sorted(data):
            for s, v in data[tag]:
                w.writerow([tag, s, v])

    palette = plt.rcParams["axes.prop_cycle"].by_key()["color"]

    # success curve
    fig, ax = plt.subplots(figsize=(7, 4.2))
    for i, (tag, label) in enumerate(
        [("env/success_once", "train rollout"), ("eval/success_once", "eval")]
    ):
        xs, ys = series(data, tag)
        if not xs:
            continue
        ys_s = smooth(ys, args.window)
        ax.plot(xs, ys, ".", color=palette[i], alpha=0.25)
        ax.plot(xs, ys_s, "-", color=palette[i], label=label, lw=1.8)
    if args.baseline is not None:
        ax.axhline(args.baseline, ls="--", color="grey", lw=1.2,
                   label=f"SFT baseline {args.baseline:.1%}")
    ax.set_xlabel("iteration")
    ax.set_ylabel("success rate")
    ax.set_ylim(-0.02, 1.02)
    ax.set_title(f"FlowSDE PPO on RoboCasa {args.task}: success")
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(os.path.join(args.outdir, "fig_success.png"), dpi=160)
    plt.close(fig)

    # reward / return curve
    fig, ax = plt.subplots(figsize=(7, 4.2))
    for i, (tag, label) in enumerate(
        [("env/return", "train episode return"), ("eval/return", "eval episode return")]
    ):
        xs, ys = series(data, tag)
        if not xs:
            continue
        ax.plot(xs, ys, ".", color=palette[i], alpha=0.25)
        ax.plot(xs, smooth(ys, args.window), "-", color=palette[i], label=label, lw=1.8)
    ax.set_xlabel("iteration")
    ax.set_ylabel("episode return (sparse 0/1)")
    ax.set_title(f"FlowSDE PPO on RoboCasa {args.task}: reward")
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(os.path.join(args.outdir, "fig_reward.png"), dpi=160)
    plt.close(fig)

    # training diagnostics
    wanted = [
        ("train/actor/policy_loss_abs", "actor |policy loss|"),
        ("train/critic/value_loss", "value loss"),
        ("train/actor/grad_norm", "grad norm"),
        ("train/actor/ratio", "PPO ratio"),
        ("train/critic/explained_variance", "value explained var"),
    ]
    present = [(t, l) for t, l in wanted if series(data, t)[0]]
    if present:
        fig, axes = plt.subplots(len(present), 1, figsize=(7, 2.2 * len(present)), sharex=True)
        if len(present) == 1:
            axes = [axes]
        for ax, (tag, label) in zip(axes, present):
            xs, ys = series(data, tag)
            ax.plot(xs, ys, ".", alpha=0.25)
            ax.plot(xs, smooth(ys, args.window), "-", lw=1.4)
            ax.set_ylabel(label)
            ax.grid(alpha=0.3)
        axes[-1].set_xlabel("iteration")
        fig.suptitle("FlowSDE PPO training diagnostics")
        fig.tight_layout()
        fig.savefig(os.path.join(args.outdir, "fig_training.png"), dpi=160)
        plt.close(fig)

    summary = {
        "task": args.task,
        "baseline": args.baseline,
        "final_train_success": (series(data, "env/success_once")[1][-1] if series(data, "env/success_once")[0] else None),
        "final_eval_success": (series(data, "eval/success_once")[1][-1] if series(data, "eval/success_once")[0] else None),
        "max_eval_success": (max(series(data, "eval/success_once")[1]) if series(data, "eval/success_once")[0] else None),
        "num_points": {t: len(v) for t, v in data.items()},
    }
    with open(os.path.join(args.outdir, "summary.json"), "w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
