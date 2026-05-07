#!/bin/bash
# Run the DeepSeek-VL2-Small RGBDM benchmark.
# Usage: bash scripts/run/Run_deepseek_vl2_small_rgbdm.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

if ! cd "$PROJECT_DIR"; then
    echo "Failed to enter project directory: $PROJECT_DIR"
    exit 1
fi

if [ -n "${PYTHON_BIN:-}" ]; then
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        echo "Configured PYTHON_BIN was not found on PATH: $PYTHON_BIN"
        exit 1
    fi
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo "Neither python3 nor python was found on PATH."
    exit 1
fi

CONFIG="configs/Benchmark_config_deepseek_vl2_small_rgbdm.yaml"
LOG_DIR="${LOG_DIR:-$PROJECT_DIR/logs}"
LOG_FILE="$LOG_DIR/deepseek-vl2-small_rgbdm.log"
mkdir -p "$LOG_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "Missing config file: $CONFIG"
    exit 1
fi

echo "Checking DeepSeek Python environment..."
"$PYTHON_BIN" - <<PY
import sys
import numpy as np
import torch
import yaml

major = int(str(np.__version__).split(".", 1)[0])
if major >= 2:
    raise SystemExit(
        f"NumPy {np.__version__} is not compatible with this DeepSeek/Torch stack. "
        'Run: python -m pip install "numpy<2"'
    )

torch.tensor([1]).cpu().numpy()
with open("$CONFIG", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)
device = str(cfg.get("model", {}).get("device", "")).lower()
if device.startswith("cuda") and not torch.cuda.is_available():
    raise SystemExit("Config requests CUDA, but torch.cuda.is_available() is false.")

print(f"Python: {sys.executable}")
print(f"NumPy: {np.__version__}")
print(f"Torch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print("Tensor-to-NumPy check: ok")
PY

echo "Starting DeepSeek-VL2-Small RGBDM benchmark..."
echo "Python: $PYTHON_BIN"
nohup "$PYTHON_BIN" -m src.main --config "$CONFIG" > "$LOG_FILE" 2>&1 &
PID=$!

echo "PID: $PID"
echo "Log: $LOG_FILE"
echo "Follow log: tail -f $LOG_FILE"
echo "Stop run: kill $PID"

wait "$PID"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
    echo "=== DeepSeek-VL2-Small RGBDM run completed successfully ==="
else
    echo "=== DeepSeek-VL2-Small RGBDM run failed; check the log above ==="
fi
exit "$STATUS"
