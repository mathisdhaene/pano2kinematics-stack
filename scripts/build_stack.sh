#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PREFIX="${PREFIX:-$ROOT/local_install}"
CONC_PREFIX="${CONC_PREFIX:-$PREFIX/concurrency}"
FILT_PREFIX="${FILT_PREFIX:-$PREFIX/filter}"

# 1) deps
"$ROOT/scripts/build_deps.sh"

# 2) theta streamer
echo "[stack] build theta-x-stream-tools"
make -C "$ROOT/deps/theta-x-stream-tools"

# 3) my_online_ik (consume deps from umbrella)
echo "[stack] build my_online_ik"
export CONCURRENCY_INSTALL="$CONC_PREFIX"
export FILTER_INSTALL="$FILT_PREFIX"
bash "$ROOT/deps/my_online_ik/scripts/build_all.sh"

echo "[stack] build done"
