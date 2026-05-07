#!/bin/bash
# Run a Gemini RGBDM benchmark config.
# Usage:
#   bash scripts/run/Run_gemini_rgbdm.sh
#   CONFIG=configs/Benchmark_config_gemini_2_5_pro_rgbdm.yaml bash scripts/run/Run_gemini_rgbdm.sh
#   BATCH_RUNS=100 CONFIG=configs/Benchmark_config_gemini_2_5_pro_rgbdm.yaml bash scripts/run/Run_gemini_rgbdm.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

if ! cd "$PROJECT_DIR"; then
    echo "Failed to enter project directory: $PROJECT_DIR"
    exit 1
fi

if [ -z "${GOOGLE_API_KEY:-}" ]; then
    echo "Please set GOOGLE_API_KEY first:"
    echo "  export GOOGLE_API_KEY='<your-google-api-key>'"
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

CONFIG="${CONFIG:-configs/Benchmark_config_gemini_2_5_flash_rgbdm.yaml}"
LOG_DIR="${LOG_DIR:-$PROJECT_DIR/logs}"
mkdir -p "$LOG_DIR"

if [ ! -f "$CONFIG" ]; then
    echo "Missing config file: $CONFIG"
    exit 1
fi

EXPERIMENT_NAME="$("$PYTHON_BIN" - <<PY
import yaml
with open("$CONFIG", encoding="utf-8") as f:
    print(yaml.safe_load(f)["experiment_name"])
PY
)"
LOG_FILE="$LOG_DIR/${EXPERIMENT_NAME}.log"
BATCH_RUNS="${BATCH_RUNS:-1}"
BATCH_SLEEP_SEC="${BATCH_SLEEP_SEC:-2}"

echo "Starting Gemini RGBDM benchmark..."
echo "Config: $CONFIG"
echo "Log: $LOG_FILE"
echo "Follow log: tail -f $LOG_FILE"
echo "Batch runs: $BATCH_RUNS"

: > "$LOG_FILE"

STATUS=0
for ((BATCH_ID=1; BATCH_ID<=BATCH_RUNS; BATCH_ID++)); do
    {
        echo ""
        echo "============================================================"
        echo "Gemini batch $BATCH_ID / $BATCH_RUNS"
        echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================================"
    } >> "$LOG_FILE"

    nohup "$PYTHON_BIN" -m src.main --config "$CONFIG" >> "$LOG_FILE" 2>&1 &
    PID=$!

    echo "Batch $BATCH_ID/$BATCH_RUNS PID: $PID"
    echo "Stop current batch: kill $PID"

    wait "$PID"
    STATUS=$?

    if [ "$STATUS" -ne 0 ]; then
        echo "=== Gemini batch $BATCH_ID failed; check the log above ==="
        exit "$STATUS"
    fi

    {
        echo "Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Batch $BATCH_ID completed successfully."
    } >> "$LOG_FILE"

    if [ "$BATCH_ID" -lt "$BATCH_RUNS" ]; then
        sleep "$BATCH_SLEEP_SEC"
    fi
done

echo "=== Gemini RGBDM batch run completed successfully ==="
exit 0
