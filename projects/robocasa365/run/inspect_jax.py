import sys, json, pathlib
sys.path.insert(0, "/root/autodl-tmp/RLinf")
from rlinf.utils.ckpt_convertor.openpi.jax_to_openpi import _load_jax_params

ck = "/autodl-fs/data/robocasa365/models/pi05_pretrain_human300/multitask_learning/75000"
p = _load_jax_params(ck)
print("top keys", list(p.keys())[:20], flush=True)

def walk(d, prefix="", depth=0):
    for k, v in d.items():
        name = f"{prefix}/{k}" if prefix else k
        if isinstance(v, dict):
            yield from walk(v, name, depth + 1)
        else:
            yield name, getattr(v, "shape", None), getattr(v, "dtype", None)

items = list(walk(p))
print("num leaves", len(items), flush=True)
for n, s, d in items:
    if any(t in n for t in ["action_out", "action_in", "time_mlp", "state_proj", "action_expert", "embed_tokens", "final_logits"]):
        print(n, s, d, flush=True)
