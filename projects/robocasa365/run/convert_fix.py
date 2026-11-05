import pathlib, sys
sys.path.insert(0, "/root/autodl-tmp/code/RLinf")
import torch
from rlinf.utils.ckpt_convertor.openpi.jax_to_openpi import (
    _load_jax_params,
    convert_siglip,
    convert_llm,
    convert_projections,
)
from rlinf.utils.ckpt_convertor.openpi._core import (
    save_safetensors,
    write_config_json,
    copy_norm_stats,
)


def unwrap(x):
    if isinstance(x, dict):
        if set(x.keys()) == {"value"}:
            return x["value"]
        return {k: unwrap(v) for k, v in x.items()}
    return x


def main():
    inp = pathlib.Path("/autodl-fs/data/artifacts/robocasa365/models/pi05_pretrain_human300/multitask_learning/75000")
    out = pathlib.Path("/autodl-fs/data/artifacts/robocasa365/models/pi05_robocasa365_openpi")
    ns = inp / "assets" / "norm_stats.json"
    out.mkdir(parents=True, exist_ok=True)
    print("loading jax params...", flush=True)
    params = unwrap(_load_jax_params(inp))
    print("loaded; keys", list(params.keys()), flush=True)

    merged = {}
    for name, part in (
        ("siglip", convert_siglip(params)),
        ("llm", convert_llm(params, True)),
        ("proj", convert_projections(params, True)),
    ):
        print(name, "tensors", len(part), flush=True)
        for k, v in part.items():
            merged[k] = v.contiguous()

    print("total tensors", len(merged), flush=True)
    save_safetensors(merged, out / "model.safetensors")
    write_config_json(
        {
            "action_dim": 32,
            "action_horizon": 50,
            "max_token_len": 200,
            "paligemma_variant": "gemma_2b",
            "action_expert_variant": "gemma_300m",
            "pi05": True,
            "pcd": False,
            "dtype": "bfloat16",
        },
        out,
    )
    copy_norm_stats(ns, out / "assets" / "norm_stats.json")
    print("CONVERT_DONE", out, flush=True)


main()
