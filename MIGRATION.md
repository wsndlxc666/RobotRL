# 目录结构迁移(待执行)

**状态**: 等待训练结束 —— 当前有 365 的 FlowSDE 训练在跑,移动 `RLinf`/`models`/`assets` 会打断它。

## 触发条件

`robocasa365_flowsde_opendrawer_pi05` 训练及其内置评测结束之后执行。

## 执行

```bash
/autodl-fs/data/lab/tools/migrate_layout.sh --dry-run     # 先看
/autodl-fs/data/lab/tools/migrate_layout.sh --apply       # 再做
/autodl-fs/data/lab/tools/bootstrap.sh all                # 体检
```

预期耗时:大文件都在同一文件系统内,`mv` 是重命名,几秒完成;耗时主要在 venv 的 editable 重装。

## 目标结构

```
/autodl-fs/data/
├── lab/                                  git 仓库
└── artifacts/
    ├── shared/models/                    pi05_base_*, tokenizer, siglip2, gemma, normstats
    ├── recap/{models,ckpt,data,report}/
    ├── robocasa_v0/{models,ckpt,data,report}/
    └── robocasa365/{models,ckpt,data/assets}/

/root/autodl-tmp/
├── code/{RLinf,robocasa_v0,robocasa365,robosuite_master,openpi->}
├── projects/<proj>/{logs,ckpt,tb}/
└── cache/{uv,uv_python,hf}/
```

## 兼容策略

所有旧路径留软链:
- `/autodl-fs/data/{recap,robocasa,robocasa365,robocasa365_assets}`
- `/autodl-fs/data/artifacts/recap/models/<shared 名称>`
- `/root/autodl-tmp/{.uv_cache,.uv_python,hf}`

## 迁移后必须验证

1. `migrate_layout.sh verify` 全部 ✓
2. 三个 venv 都能 `import rlinf` / `import robocasa` / `import robosuite`
3. 用 `tools/bootstrap.sh all` 确认代码 commit 与 manifest 一致
4. `git -C /autodl-fs/data/lab status` 干净,然后 commit + push

## 已知风险

| 风险 | 处理 |
|---|---|
| 移动 RLinf 后 venv 的 console script shebang 失效 | 脚本会 sed 修正 |
| editable 包记录的是绝对路径 | 脚本会重新 `pip install -e . --no-deps` |
| v0 源码从 `.venv-robocasa/robocasa` 搬出后 robocasa 导入失败 | 重新 editable 安装;失败则把 `code/robocasa_v0` 移回并回滚 |
| `_downloads/*.zip` 与解压内容重复 11G | 迁移后单独确认删除 |

## 关机流程

全部做完后关实例:

```bash
tools/shutdown_if_done.sh --yes
```

它会:

1. 跑 `finalize.sh`(迁移 → 体检 → 归档日志 → 提交推送),失败即停;
2. 确认本地没有未推送的提交、`/autodl-fs/data/{lab,artifacts}` 都在、无训练进程;
3. 5 秒倒计时后调用 `/usr/bin/shutdown`(AutoDL 的关机脚本,会停掉 supervisord)。

**关机前必须成立的条件**:所有产物已在 `/autodl-fs/data`(持久)和 GitHub 上。
`/root/autodl-tmp` 是实例本地盘,关机后可能被重置,不能作为唯一存放点。

