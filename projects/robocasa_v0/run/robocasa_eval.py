#!/usr/bin/env python
"""Standalone RoboCasa evaluation for RLinf openpi pi0/pi0.5 checkpoints.

Builds the model directly from the same actor.model config used by the RL
training YAML, so the observation/action transforms (including any
`action_remap`) are identical to training. Runs N seeded trials per task.

Usage:
  python robocasa_eval.py --model-path <ckpt> --task CloseDrawer --trials 10
  python robocasa_eval.py --model-path <ckpt> --task CloseDrawer --random
"""
import argparse
import json
import os
import time

import numpy as np
import torch
from omegaconf import OmegaConf

import robocasa  # noqa: F401
import robosuite
from robosuite.controllers import load_composite_controller_config

from rlinf.models.embodiment.openpi import get_model


DEFAULT_REMAP = {
    "indices": [5, 6, 7, 8, 9, 10, 11, -1, -1, -1, -1, -1],
    "constants": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1],
    "scale": [1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1],
    "shift": [0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0],
}


def build_model(args):
    openpi_data = {
        "action_space": "12d",
        "state_space": args.state_space,
        "image_space": args.image_space,
    }
    if args.remap == "canonical":
        pass
    elif args.remap == "pi05_100demos":
        openpi_data["action_remap"] = DEFAULT_REMAP
    else:
        raise ValueError(f"unknown --remap {args.remap}")
    if args.norm_stats_path:
        openpi_data["norm_stats_path"] = args.norm_stats_path

    cfg = OmegaConf.create(
        {
            "model_path": args.model_path,
            "model_type": "openpi",
            "pi05": True,
            "precision": "bf16",
            "num_action_chunks": args.chunk,
            "num_steps": args.num_steps,
            "action_dim": 12,
            "add_value_head": False,
            "openpi": {
                "task": "eval",
                "config_name": args.config_name,
                "num_images_in_input": 2,
                "detach_critic_input": True,
                "joint_logprob": False,
                "value_after_vlm": True,
                "noise_method": "flow_sde",
                "noise_level": args.noise_level,
                "action_chunk": args.chunk,
                "action_horizon": 50,
                "action_env_dim": 12,
                "model_action_dim": 32,
                "torch_compile": False,
                "train_expert_only": True,
                "paligemma_variant": "gemma_2b",
                "action_expert_variant": "gemma_300m",
                "max_token_len": 200,
            },
            "openpi_data": openpi_data,
        }
    )
    model = get_model(cfg).to("cuda").eval()
    return model


def make_env(task, seed, image_space):
    cameras = ["robot0_agentview_left", "robot0_eye_in_hand"]
    if image_space == "3views":
        cameras.append("robot0_agentview_right")
    controller = load_composite_controller_config(controller=None, robot="PandaOmron")
    return robosuite.make(
        env_name=task,
        robots="PandaOmron",
        controller_configs=controller,
        camera_names=cameras,
        camera_widths=224,
        camera_heights=224,
        has_renderer=False,
        has_offscreen_renderer=True,
        ignore_done=True,
        use_object_obs=True,
        use_camera_obs=True,
        camera_depths=False,
        seed=seed,
        translucent_robot=False,
        render_camera="robot0_agentview_center",
    )


def state_25d(obs):
    s = np.zeros(25, dtype=np.float32)
    s[0:3] = obs["robot0_eef_pos"]
    s[3:7] = obs["robot0_eef_quat"]
    s[7:9] = obs["robot0_gripper_qpos"]
    s[9:11] = obs["robot0_gripper_qvel"]
    s[11:14] = obs["robot0_base_to_eef_pos"]
    s[14:18] = obs["robot0_base_to_eef_quat"]
    s[18:21] = obs["robot0_base_pos"]
    s[21:25] = obs["robot0_base_quat"]
    return s


def build_env_obs(obs, lang, image_space):
    main = obs["robot0_agentview_left_image"][::-1]
    wrist = obs["robot0_eye_in_hand_image"][::-1]
    env_obs = {
        "states": state_25d(obs)[None],
        "main_images": main[None],
        "wrist_images": wrist[None],
        "task_descriptions": [lang],
    }
    if image_space == "3views":
        env_obs["extra_view_images"] = obs["robot0_agentview_right_image"][::-1][None]
    return env_obs


def run_trial(model, args, task, seed, record_video=False):
    torch.manual_seed(seed)
    np.random.seed(seed)
    env = make_env(task, seed, args.image_space)
    obs = env.reset()
    lang = env.get_ep_meta().get("lang", "")
    success = False
    ret = 0.0
    n = 0
    action_stats = []
    frames = []
    t0 = time.time()
    while n < args.max_steps:
        if args.random:
            acts = np.random.uniform(-0.3, 0.3, size=(args.chunk, 12)).astype(np.float32)
            acts[:, 6] = np.random.choice([-1.0, 1.0], size=(args.chunk,))
            acts[:, 7:11] = 0.0
            acts[:, 11] = -1.0
        else:
            env_obs = build_env_obs(obs, lang, args.image_space)
            with torch.no_grad():
                acts, _ = model.predict_action_batch(env_obs, mode="eval")
            acts = acts.detach().cpu().float().numpy()[0]
        action_stats.append(np.asarray(acts).reshape(-1, 12))
        for a in acts:
            obs, reward, done, info = env.step(a)
            ret += float(reward)
            n += 1
            if record_video and len(frames) < args.max_steps:
                frames.append(obs["robot0_agentview_left_image"][::-1])
            if env._check_success():
                success = True
                break
            if n >= args.max_steps:
                break
        if success:
            break
    env.close()
    acts = np.concatenate(action_stats, axis=0) if action_stats else np.zeros((1, 12))
    stats = {
        "task": task,
        "seed": int(seed),
        "success": bool(success),
        "steps": int(n),
        "return": float(ret),
        "secs": round(time.time() - t0, 2),
        "action_mean": np.round(acts.mean(0), 4).tolist(),
        "action_std": np.round(acts.std(0), 4).tolist(),
        "action_min": np.round(acts.min(0), 4).tolist(),
        "action_max": np.round(acts.max(0), 4).tolist(),
        "is_finite": bool(np.isfinite(acts).all()),
    }
    if record_video and frames:
        import imageio

        os.makedirs(args.video_dir, exist_ok=True)
        path = os.path.join(args.video_dir, f"{task}_seed{seed}_success{int(success)}.mp4")
        imageio.mimsave(path, frames, fps=10)
        stats["video"] = path
    return stats


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model-path", required=True)
    ap.add_argument("--task", default="CloseDrawer")
    ap.add_argument("--trials", type=int, default=10)
    ap.add_argument("--max-steps", type=int, default=300)
    ap.add_argument("--chunk", type=int, default=5)
    ap.add_argument("--num-steps", type=int, default=3)
    ap.add_argument("--noise-level", type=float, default=0.5)
    ap.add_argument("--config-name", default="pi05_robocasa_human_100demos")
    ap.add_argument("--state-space", default="16d_pi05_100demos")
    ap.add_argument("--image-space", default="2views", choices=["2views", "3views"])
    ap.add_argument("--remap", default="pi05_100demos", choices=["canonical", "pi05_100demos"])
    ap.add_argument("--norm-stats-path", default="")
    ap.add_argument("--random", action="store_true", help="random-action state statistics")
    ap.add_argument("--seed0", type=int, default=0)
    ap.add_argument("--video", action="store_true")
    ap.add_argument("--video-max", type=int, default=0,
                    help="record at most N trials when --video is set (0 = all)")
    ap.add_argument("--video-dir", default="/root/autodl-tmp/robocasa_rl/report/videos")
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    model = None if args.random else build_model(args)
    results = []
    for i in range(args.trials):
        seed = args.seed0 + i
        record_video = args.video and (args.video_max <= 0 or i < args.video_max)
        st = run_trial(model, args, args.task, seed, record_video=record_video)
        results.append(st)
        print(
            f"[{args.task}] trial {i + 1}/{args.trials} seed={seed} "
            f"success={st['success']} steps={st['steps']} ret={st['return']:.2f} "
            f"act[min,max]={st['action_min'][6]:.2f},{st['action_max'][6]:.2f} "
            f"({'grip' if args.remap == 'pi05_100demos' else ''})",
            flush=True,
        )
    n_ok = sum(r["success"] for r in results)
    summary = {
        "task": args.task,
        "trials": args.trials,
        "successes": n_ok,
        "success_rate": n_ok / max(args.trials, 1),
        "args": vars(args),
        "results": results,
    }
    print(json.dumps({k: v for k, v in summary.items() if k != "results"}, indent=2))
    if args.out:
        with open(args.out, "w") as f:
            json.dump(summary, f, indent=2)
        print("wrote", args.out)


if __name__ == "__main__":
    main()
