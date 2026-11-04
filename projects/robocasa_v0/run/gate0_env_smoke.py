#!/usr/bin/env python
"""Gate 0: single-process RoboCasa env smoke test (EGL render + step + success)."""
import argparse
import numpy as np

import robocasa  # noqa: F401  (registers RoboCasa tasks)
import robosuite
from robosuite.controllers import load_composite_controller_config


def make_env(task, seed=0, cameras=("robot0_agentview_left", "robot0_eye_in_hand")):
    controller = load_composite_controller_config(controller=None, robot="PandaOmron")
    return robosuite.make(
        env_name=task,
        robots="PandaOmron",
        controller_configs=controller,
        camera_names=list(cameras),
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--task", default="CloseDrawer")
    ap.add_argument("--steps", type=int, default=5)
    args = ap.parse_args()

    env = make_env(args.task)
    obs = env.reset()
    print("task:", args.task)
    print("obs keys:", sorted(obs.keys()))
    print("ep_meta:", env.get_ep_meta())
    print("action dim:", env.action_dim)
    print("obs keys:", [k for k in obs.keys() if "image" in k or k.endswith("_pos")][:12])
    for i in range(args.steps):
        act = np.zeros(12, dtype=np.float32)
        act[11] = -1.0
        obs, reward, done, info = env.step(act)
        ok = env._check_success()
        img = obs["robot0_agentview_left_image"]
        print(
            f"step {i}: reward={reward:.4f} success={ok} "
            f"img={img.shape}/{img.dtype} eef={np.round(obs['robot0_eef_pos'], 3)}"
        )
    env.close()
    print("GATE0_OK")


if __name__ == "__main__":
    main()
