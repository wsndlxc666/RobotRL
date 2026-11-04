import json, numpy as np
import robocasa  # noqa
import robosuite
from robosuite.controllers import load_composite_controller_config

CK = "/root/autodl-fs/robocasa/models/pi05_robocasa_100demos_s30000/30000"
ns = json.load(open(f"{CK}/physical-intelligence/robocasa_100demos/norm_stats.json"))["norm_stats"]["state"]
ref_mean = np.array(ns["mean"][:16]); ref_std = np.array(ns["std"][:16])

cc = load_composite_controller_config(controller=None, robot="PandaOmron")
env = robosuite.make(env_name="CloseDrawer", robots="PandaOmron", controller_configs=cc,
    camera_names=["robot0_agentview_left","robot0_eye_in_hand"], camera_widths=224, camera_heights=224,
    has_renderer=False, has_offscreen_renderer=True, ignore_done=True, use_object_obs=True,
    use_camera_obs=True, camera_depths=False, seed=0, translucent_robot=False,
    render_camera="robot0_agentview_center")
sel = list(range(18,21))+list(range(21,25))+list(range(7,9))+list(range(11,14))+list(range(14,18))
S=[]
for ep in range(6):
    env.reset()
    rng=np.random.default_rng(ep)
    for t in range(40):
        a=np.zeros(12,dtype=np.float32); a[5:11]=rng.normal(0,0.2,6); a[11]=rng.choice([-1,1])
        obs,_,_,_=env.step(a)
        s=np.zeros(25,np.float32)
        s[0:3]=obs["robot0_eef_pos"]; s[3:7]=obs["robot0_eef_quat"]; s[7:9]=obs["robot0_gripper_qpos"]
        s[9:11]=obs["robot0_gripper_qvel"]; s[11:14]=obs["robot0_base_to_eef_pos"]
        s[14:18]=obs["robot0_base_to_eef_quat"]; s[18:21]=obs["robot0_base_pos"]; s[21:25]=obs["robot0_base_quat"]
        S.append(s[sel])
env.close(); S=np.array(S)
print("shape", S.shape)
print("our mean:", np.round(S.mean(0),3).tolist())
print("ref mean:", np.round(ref_mean,3).tolist())
print("our std :", np.round(S.std(0),3).tolist())
print("ref std :", np.round(ref_std,3).tolist())
# structural checks
print("dim0-2 large base x/y, const z:", S[:,0].std()>0.3, S[:,1].std()>0.2, S[:,2].std()<0.01)
print("dim3-4 base_quat xy ~0:", abs(S[:,3]).max()<0.05, abs(S[:,4]).max()<0.05)
print("dim5-6 base_quat zw:", S[:,5].std()>0.1, S[:,6].std()>0.05)
print("dim7-8 gripper qpos:", S[:,7].mean(), S[:,8].mean())
print("dim9-11 b2eef pos:", np.round(S[:,9:12].mean(0),3))
print("GATE2_OK")
