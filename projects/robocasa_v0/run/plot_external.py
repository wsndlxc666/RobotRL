#!/usr/bin/env python
"""Bar chart of external eval success rates with Wilson 95% CIs."""
import argparse
import json
import math
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def wilson(k, n, z=1.96):
    if n == 0:
        return 0.0, 0.0, 0.0
    p = k / n
    denom = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / denom
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / denom
    return p, max(0.0, centre - half), min(1.0, centre + half)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", nargs="+", required=True,
                    help="label:path pairs, e.g. baseline:/path/a.json")
    ap.add_argument("--out", required=True)
    ap.add_argument("--task", default="CloseDrawer")
    args = ap.parse_args()

    labels, ps, los, his, ns = [], [], [], [], []
    for item in args.items:
        label, path = item.split(":", 1)
        d = json.load(open(path))
        k, n = d["successes"], d["trials"]
        p, lo, hi = wilson(k, n)
        labels.append(label)
        ps.append(p); los.append(p - lo); his.append(hi - p); ns.append(n)
        print(f"{label}: {k}/{n} = {p:.3f} [{lo:.3f}, {hi:.3f}]")

    fig, ax = plt.subplots(figsize=(6.6, 4.2))
    bars = ax.bar(labels, ps, yerr=[los, his], capsize=5,
                  color=["#9aa0a6", "#7aa6d6", "#5b8fd0", "#2f6db5"][: len(labels)])
    for bar, p, n in zip(bars, ps, ns):
        ax.text(bar.get_x() + bar.get_width() / 2, p + 0.03,
                f"{p:.1%}\n(n={n})", ha="center", va="bottom", fontsize=9)
    ax.set_ylabel("success rate")
    ax.set_ylim(0, 0.85)
    ax.set_title(f"FlowSDE PPO on RoboCasa {args.task}: zero-shot success")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    fig.savefig(args.out, dpi=160)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
