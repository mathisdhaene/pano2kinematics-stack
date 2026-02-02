#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NPROC="$(command -v nproc >/dev/null 2>&1 && nproc || echo 4)"

PREFIX="${PREFIX:-$ROOT/local_install}"
CONC_PREFIX="${CONC_PREFIX:-$PREFIX/concurrency}"
FILT_PREFIX="${FILT_PREFIX:-$PREFIX/filter}"

echo "[deps] prefix: $PREFIX"
mkdir -p "$PREFIX"

echo "[deps] build Concurrency -> $CONC_PREFIX"
mkdir -p "$ROOT/build/concurrency"
cmake -S "$ROOT/deps/concurrency" -B "$ROOT/build/concurrency" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$CONC_PREFIX"
cmake --build "$ROOT/build/concurrency" -j"$NPROC"
cmake --install "$ROOT/build/concurrency"

echo "[deps] build Filter -> $FILT_PREFIX"
mkdir -p "$ROOT/build/filter"
cmake -S "$ROOT/deps/filter" -B "$ROOT/build/filter" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$FILT_PREFIX" \
  -DCMAKE_PREFIX_PATH="$CONC_PREFIX"
cmake --build "$ROOT/build/filter" -j"$NPROC"
cmake --install "$ROOT/build/filter"

echo "[deps] done"
echo "[deps] Concurrency: $CONC_PREFIX"
echo "[deps] Filter:      $FILT_PREFIX"
