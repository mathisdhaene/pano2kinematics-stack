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

### OpenSim toolchain setup (required before `make build`)

`make build` compiles `my_online_ik` / RTOSIM and will fail if OpenSim, Simbody, and SWIG are not installed first.

Install system dependencies:
```bash
sudo apt-get update
sudo apt-get install --yes \
  build-essential \
  libtool autoconf pkg-config gfortran \
  libopenblas-dev liblapack-dev \
  freeglut3-dev libxi-dev libxmu-dev \
  doxygen \
  python3 python3-dev python3-numpy python3-setuptools
```

Build SWIG 4.1.1:
```bash
mkdir -p ~/swig-release && cd ~/swig-release
wget https://sourceforge.net/projects/swig/files/swig/swig-4.1.1/swig-4.1.1.tar.gz/download -O swig-4.1.1.tar.gz
tar xzf swig-4.1.1.tar.gz
cd swig-4.1.1
./configure --prefix="$HOME/swig"
make -j"$(nproc)"
make install
```

Build OpenSim 4.3 (dependencies + install):
```bash
cd ~
git clone https://github.com/opensim-org/opensim-core.git
cd opensim-core
git checkout 4.3

mkdir -p ~/build_opensim_deps && cd ~/build_opensim_deps
cmake ../opensim-core/dependencies \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/opensim_dependencies_install" \
  -DSUPERBUILD_ezc3d=ON \
  -DOPENSIM_WITH_CASADI=ON
make -j"$(nproc)"

mkdir -p ~/build_opensim && cd ~/build_opensim
cmake ../opensim-core \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/opensim-core-install" \
  -DOPENSIM_DEPENDENCIES_DIR="$HOME/opensim_dependencies_install" \
  -DOPENSIM_C3D_PARSER=ezc3d \
  -DBUILD_PYTHON_WRAPPING=ON \
  -DBUILD_JAVA_WRAPPING=OFF \
  -DSWIG_DIR="$HOME/swig/share/swig" \
  -DSWIG_EXECUTABLE="$HOME/swig/bin/swig" \
  -DOPENSIM_WITH_TROPTER=OFF \
  -DBUILD_TESTING=OFF
make -j"$(nproc)"
make install
```

For the full and maintained instructions (including env setup and known fixes), see:
- `deps/my_online_ik/README.md`

If OpenSim was installed in non-default locations, export paths before building:
```bash
export OPENSIM_PREFIX=/your/opensim-core-install
export OPENSIM_DEPS_PREFIX=/your/opensim-deps-install
export SIMBODY_PREFIX="$OPENSIM_DEPS_PREFIX/simbody"
```
or use:
```bash
source deps/my_online_ik/scripts/env.sh
```

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
cd ~
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
- force `--system-site-packages` so `python3-gi` is visible in the venv

The environment uses **system site-packages** so that `python3-gi` is visible.

Quick validation:
```bash
python3 -c "import gi"
deps/pano2kinematics/.venv/bin/python -c "import gi"
```

---

## 4) Download NLF weights (REQUIRED)

The NLF pipeline requires TorchScript weights that are **not tracked by git**.

Expected path:
```
deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript
```

Inside the `pano2kinematics` submodule, create the weights tree if needed:
```bash
mkdir -p deps/pano2kinematics/weights/nlf deps/pano2kinematics/weights/yolo_models
```

Then download and place the NLF weight file in `deps/pano2kinematics/weights/nlf/`:
```
nlf_s_multi.torchscript
```

Download source:
- Release page: https://github.com/isarandi/nlf/releases/tag/v0.2.0
- File: `nlf_s_multi.torchscript` (from https://github.com/isarandi/nlf/releases)

Direct download (choose one):
```bash
wget -O deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript \
  https://github.com/isarandi/nlf/releases/download/v0.2.0/nlf_s_multi.torchscript
```

```bash
curl -L \
  https://github.com/isarandi/nlf/releases/download/v0.2.0/nlf_s_multi.torchscript \
  -o deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript
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

### Temporary workaround (recommended for now)

`make run` can be unstable on some machines because `online_ik_test` may fail intermittently and the Simbody visualizer may not open.

Until this is fixed, prefer running the stack manually in **3 terminals**:

1. **Terminal 1: Theta streaming**
```bash
cd deps/theta-x-stream-tools
./min_latency_from_uvc
```

2. **Terminal 2: Online IK**  
If Simbody crashes or the visualizer does not open, relaunch this command.
```bash
cd deps/my_online_ik
source scripts/env.sh
export CONCURRENCY_INSTALL="$PWD/../../local_install/concurrency"
export FILTER_INSTALL="$PWD/../../local_install/filter"
./build/online_ik_test data/upperlimb-biorob_nomuscle.osim
```

3. **Terminal 3: Python markerless pipeline**
```bash
cd deps/pano2kinematics
uv run python live_cpu.py --live --shm-socket /tmp/theta_bgr.sock --fps 30 --device cpu \
  --yolo weights/yolo_models/yolo11m-pose.pt --tracker bytetrack.yaml \
  --bio-cfg configs/biomeca.yaml \
  --nlf-weights weights/nlf/nlf_s_multi.torchscript \
  -o output_nlf/markerless_live.mp4
```

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

If the first command works but the second fails, recreate the venv:
```bash
rm -rf deps/pano2kinematics/.venv
make py
```

### `matplotlib` mismatch with `--system-site-packages`
Symptom:
- `uv run` can import `gi`, but `matplotlib` emits warnings/errors (for example `Axes3D` import failures).

Cause:
- system `python3-matplotlib` leaks `mpl_toolkits` into the venv while `matplotlib` itself comes from `uv`, creating a mixed-version import.

Fix:
```bash
sudo apt remove -y python3-matplotlib
rm -rf deps/pano2kinematics/.venv
make py
```

Verify import origins:
```bash
cd deps/pano2kinematics
uv run python -c "import gi, matplotlib, mpl_toolkits.mplot3d as m3d; print(gi.__file__); print(matplotlib.__file__); print(m3d.__file__)"
```

Expected:
- `gi` from `/usr/lib/python3/dist-packages/...`
- `matplotlib` and `mplot3d` from `deps/pano2kinematics/.venv/...`

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
