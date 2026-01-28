# pano2kinematics-stack

Umbrella repository that assembles the full real-time pipeline:

1) **Theta X stream** → shared-memory socket (`/tmp/theta_bgr.sock`)
2) **Markerless pipeline** (YOLO + EquiLib + NLF) → markers
3) **Inverse Kinematics** (OpenSim/RTOSIM via `my_online_ik`)

This repo pins exact versions via **git submodules** for reproducibility.

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
    check_system.sh
    build_stack.sh
    run_tmux.sh
  Makefile
```

---

## 0) Prerequisites (system)

Tested on Ubuntu (22.04 / 24.04).

Required:
- `git`, `tmux`, `make`, `gcc/g++`
- `conda` (Miniconda/Anaconda)
- OpenSim + Simbody installed on your machine
- For Theta streaming: GStreamer dev packages + libuvc

---

## 1) Clone (with submodules)

```bash
git clone --recurse-submodules https://github.com/mathisdhaene/pano2kinematics-stack.git
cd pano2kinematics-stack
```

---

## 2) System checks

```bash
make check
```

---

## 3) Download NLF weights (REQUIRED)

The pipeline requires the TorchScript weights:

Expected path:
```
deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript
```

### Manual download

```bash
mkdir -p deps/pano2kinematics/weights/nlf
# download and place nlf_s_multi.torchscript here
```

Download link: **(ADD LINK HERE)**

---

## 4) Build everything

```bash
make build
```

After build:
```bash
ls -la deps/theta-x-stream-tools/min_latency_from_uvc
ls -la deps/my_online_ik/build/online_ik_test
```

---

## 5) Run the full stack

```bash
make run
```

This launches 3 tmux panes:
- streamer
- IK
- markerless pipeline

Detach: `Ctrl+b` then `d`

---

## Troubleshooting

### Permission denied
```bash
chmod +x scripts/*.sh
```

### Missing socket
```bash
ls -la /tmp/theta_bgr.sock*
```

### Missing weights
```bash
ls -la deps/pano2kinematics/weights/nlf/nlf_s_multi.torchscript
```

---

## Reproducibility

Submodules are pinned to exact commits:

```bash
git submodule status
```

---

## Credits

Mathis D’Haene — pano2kinematics, my_online_ik, theta-x-stream-tools  
RealTimeBiomechanics — Concurrency, Filter
