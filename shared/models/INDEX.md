# 共用模型索引

跨项目复用的权重。**不复制多份**,所有项目引用同一路径。

| 名称 | 路径 | 用途 | 来源 | 大小 |
|---|---|---|---|---|
| pi05_base_openpi | `/autodl-fs/data/recap/models/pi05_base_openpi` | pi0.5 base(JAX 版),转换源 | GCS openpi-assets | — |
| pi05_base_pytorch | `/autodl-fs/data/recap/models/pi05_base_pytorch` | pi0.5 base(PyTorch 版) | 本地转换 | — |
| openpi_tokenizer | `/autodl-fs/data/recap/models/openpi_tokenizer` | 分词器 | hf://RLinf/openpi_tokenizer | — |
| siglip2-so400m-patch14-224 | `/autodl-fs/data/recap/models/siglip2-so400m-patch14-224` | RECAP value backbone | hf://google/... | — |
| gemma-3-270m | `/autodl-fs/data/recap/models/gemma-3-270m` | RECAP value backbone | hf://google/... | — |
| RLinf-Pi05-LIBERO-SFT-normstats | `/autodl-fs/data/recap/models/RLinf-Pi05-LIBERO-SFT-normstats` | LIBERO norm stats | hf://RLinf/... | — |
| pi05_robocasa_100demos_s30000 | `/autodl-fs/data/robocasa/models/pi05_robocasa_100demos_s30000` | RoboCasa v0 策略 | hf | 7.0G |
| pi05_pretrain_human300 | `/autodl-fs/data/robocasa365/models/pi05_pretrain_human300` | RoboCasa365 策略 | hf://robocasa/robocasa365_checkpoints | 12G |
| pi05_robocasa365_openpi | `/autodl-fs/data/robocasa365/models/pi05_robocasa365_openpi` | RoboCasa365 openpi 格式 | hf://robocasa/robocasa365_checkpoints | 13G |

## 待办

- [ ] 上表的模型都还散在各项目目录里,计划统一迁到 `/autodl-fs/data/artifacts/shared/models/`,
      项目目录用软链引用
- [ ] 补 sha256 与下载日期(便于校验与复现)
