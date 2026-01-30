#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION="pano_stack"
SOCK="/tmp/theta_bgr.sock"

# Umbrella local installs
PREFIX="${PREFIX:-$ROOT/local_install}"
CONC_PREFIX="${CONC_PREFIX:-$PREFIX/concurrency}"
FILT_PREFIX="${FILT_PREFIX:-$PREFIX/filter}"

# ---- guards ----
command -v tmux >/dev/null || { echo "tmux missing (sudo apt-get install tmux)"; exit 1; }

command -v uv >/dev/null 2>&1 || {
  echo "[error] uv not found."
  echo "[fix]   Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
  exit 1
}

VENV="$ROOT/deps/pano2kinematics/.venv"
PY="$VENV/bin/python"
if [[ ! -x "$PY" ]]; then
  echo "[error] Python venv not found at: $VENV"
  echo "[fix]   Run: make py"
  exit 1
fi

# Optional: make sure weights exist before launching tmux
NLF_WEIGHTS="$ROOT/deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript"
if [[ ! -f "$NLF_WEIGHTS" ]]; then
  echo "[error] Missing NLF weights: $NLF_WEIGHTS"
  echo "[fix]   Download them (see README) into deps/pano2kinematics/weights/nlf/"
  exit 1
fi

# Commands
CMD_STREAM="cd '$ROOT/deps/theta-x-stream-tools' && ./min_latency_from_uvc"

CMD_IK="cd '$ROOT/deps/my_online_ik' \
&& source scripts/env.sh \
&& export CONCURRENCY_INSTALL='$CONC_PREFIX' \
&& export FILTER_INSTALL='$FILT_PREFIX' \
&& ./build/online_ik_test data/upperlimb-biorob.osim"

CMD_PY="cd '$ROOT/deps/pano2kinematics' \
&& '$PY' live_cpu.py --live --shm-socket '$SOCK' --fps 30 --device cpu \
   --yolo weights/yolo_models/yolo11m-pose.pt --tracker bytetrack.yaml \
   --bio-cfg configs/biomeca.yaml \
   --nlf-weights weights/nlf/nlf_s_multi.torchscript \
   -o output_nlf/markerless_live.mp4"

# tmux session
tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"
tmux new-session -d -s "$SESSION" -n stack -c "$ROOT"

tmux send-keys -t "$SESSION:0.0" "$CMD_STREAM" C-m
tmux split-window -h -t "$SESSION:0.0" -c "$ROOT"
tmux send-keys -t "$SESSION:0.1" "$CMD_IK" C-m
tmux split-window -v -t "$SESSION:0.1" -c "$ROOT"
tmux send-keys -t "$SESSION:0.2" "$CMD_PY" C-m

tmux select-layout -t "$SESSION:0" tiled
tmux attach -t "$SESSION"
