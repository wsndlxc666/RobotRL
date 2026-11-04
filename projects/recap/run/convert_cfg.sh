#!/bin/bash
# Convert an RLinf CFG checkpoint (paligemma_with_expert.* in full_weights.pt)
# to bare OpenPI layout for evaluation.
# Usage: bash convert_cfg.sh <full_weights.pt> <output_model_dir>
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
PT="$1"; OUT="$2"
STAGE="$(dirname "$PT")/openpi_pt_stage"
mkdir -p "$STAGE" "$OUT"
cp -f "$MODELS/pi05_base_pytorch/config.json" "$STAGE/config.json" 2>/dev/null || true
PYTHONPATH=$RECAP_REPO .venv/bin/python - "$PT" "$STAGE/model.safetensors" <<'PY'
import sys, torch
from safetensors.torch import save_file
sd = torch.load(sys.argv[1], map_location="cpu", weights_only=False)
if hasattr(sd, "state_dict"):
    sd = sd.state_dict()
sd = {k: v.contiguous() for k, v in sd.items() if isinstance(v, torch.Tensor)}
save_file(sd, sys.argv[2], metadata={"format": "pt"})
print("staged", len(sd), "tensors ->", sys.argv[2])
PY
PYTHONPATH=$RECAP_REPO python -m rlinf.utils.ckpt_convertor.openpi.convert --mode openpi_pytorch_to_openpi \
  --input-model "$STAGE" \
  --input-norm-stats "$NORM_STATS" \
  --output-model "$OUT" \
  --output-norm-stats "$OUT/physical-intelligence/libero/norm_stats.json"
echo "converted -> $OUT"
ls -la "$OUT"
