# pano2kinematics-stack

Umbrella repository that pins the three repos composing the live pipeline:
- theta-x-stream-tools (Theta X low-latency stream)
- my_online_ik (RTOSIM-based IK)
- pano2kinematics (YOLO+NLF inference)

## Quick start

```bash
git clone --recurse-submodules https://github.com/mathisdhaene/pano2kinematics-stack.git
cd pano2kinematics-stack
make check
make build
make run
