# pano2kinematics-stack

Umbrella repository that assembles the full real-time **markerless → biomechanical** pipeline:

1. **Theta X stream** → shared-memory socket (`/tmp/theta_bgr.sock`)
2. **Markerless pipeline** (YOLO + EquiLib + NLF) → anatomical markers
3. **Inverse Kinematics** (OpenSim / RTOSIM via `my_online_ik`)

This repository pins exact versions via **git submodules** for **reproducibility**.

---

## Repository structure

```
pano2kinematics-stack/
  deps/
    theta-x-stream-tools/
    pano2kinematics/
    my_online_ik/
    concurrency/
    filter/
  scripts/
    build_stack.sh
    build_deps.sh
    run_tmux.sh
  Makefile
  README.md
```

---

## 0) Prerequisites (system)

Tested on **Ubuntu 22.04 / 24.04**.

### Required system tools
- `git`, `make`, `tmux`
- `gcc / g++` (gcc-11 recommended)
- `pkg-config`

### Python tooling
- **uv** (Python package manager): https://astral.sh/uv

Install:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### OpenSim / Biomechanics
- **OpenSim 4.3** installed system-wide
- **Simbody** (comes with OpenSim superbuild)

Environment variables typically required:
- `OPENSIM_PREFIX`
- `OPENSIM_DEPS_PREFIX`
- `SIMBODY_PREFIX`

### GStreamer (required for live mode)
The live pipeline relies on **GStreamer + shared memory** and **Python GI bindings**.

Install on Ubuntu:
```bash
sudo apt install   gstreamer1.0-tools   gstreamer1.0-plugins-base   gstreamer1.0-plugins-good   gstreamer1.0-libav   python3-gi   python3-gi-cairo   libgirepository1.0-dev
```

⚠️ **Important**  
`gi` / `Gst` **cannot** be installed via pip or uv.  
They must come from the **system Python**.

---

## 1) Clone (with submodules)

```bash
git clone --recurse-submodules https://github.com/mathisdhaene/pano2kinematics-stack.git
cd pano2kinematics-stack
```

If already cloned:
```bash
git submodule update --init --recursive
```

---

## 2) System checks

```bash
make check
```

This verifies:
- `tmux` availability
- `uv` availability

---

## 3) Python environment (uv)

The markerless pipeline (`pano2kinematics`) uses a **local virtual environment** managed by **uv**.

```bash
make py
```

This will:
- create `deps/pano2kinematics/.venv`
- install all Python dependencies reproducibly from `pyproject.toml`
- respect the pinned Python version (3.10)

The environment uses **system site-packages** so that `python3-gi` is visible.

---

## 4) Download NLF weights (REQUIRED)

The NLF pipeline requires TorchScript weights that are **not tracked by git**.

Expected path:
```
deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript
```

Create directories if needed:
```bash
mkdir -p deps/pano2kinematics/weights/nlf
```

Then download and place:
```
nlf_s_multi.torchscript
```

⚠️ Without these weights, the markerless pipeline will not run.

---

## 5) Build everything (C++)

```bash
make build
```

This builds:
- Theta X streamer
- RTOSIM
- my_online_ik (online + offline binaries)

⚠️ The build scripts intentionally **limit the number of CPU cores**
to avoid saturating shared machines.

After build, you should see:
```bash
ls deps/theta-x-stream-tools/min_latency_from_uvc
ls deps/my_online_ik/build/online_ik_test
ls deps/my_online_ik/build/online_ik_offline
```

---

## 6) Run the full stack (LIVE)

⚠️ **Critical: startup order matters due to sockets**

The components must start in this order:

1. **Theta streaming** (creates `/tmp/theta_bgr.sock`)
2. **Online IK** (consumes markers)
3. **Python markerless pipeline** (consumes video)

This is handled automatically by tmux:

```bash
make run
```

This launches **3 tmux panes** in the correct order.

Detach from tmux:
```
Ctrl + b, then d
```

---

## 7) Offline processing (optional)

An offline IK binary is also provided:

```bash
deps/my_online_ik/build/online_ik_offline
```

This allows:
- running IK from prerecorded marker data (e.g. `.trc` files)
- no camera, no GStreamer, no sockets

Useful for:
- batch processing
- debugging IK models
- validation against motion capture

---

## Troubleshooting

### Permission denied
```bash
chmod +x scripts/*.sh
```

### Missing shared-memory socket
```bash
ls -la /tmp/theta_bgr.sock*
```

If missing, ensure the Theta streaming pane is running.

### Python cannot import `gi`
This means:
- `python3-gi` is not installed system-wide **or**
- you are not using the `.venv` created with `--system-site-packages`

Check:
```bash
python3 -c "import gi"
deps/pano2kinematics/.venv/bin/python -c "import gi"
```

---

## Reproducibility

All critical C++ dependencies are **pinned via git submodules**:

```bash
git submodule status
```

Pinned components:
- `my_online_ik`
- `Concurrency`
- `Filter`

This avoids ABI mismatches with OpenSim / Simbody and ensures deterministic builds.

---

## Credits

**Mathis D’Haene**  
- pano2kinematics
- my_online_ik
- theta-x-stream-tools

**RealTimeBiomechanics**  
- Concurrency
- Filter