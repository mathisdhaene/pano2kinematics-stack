SHELL := /usr/bin/env bash

.PHONY: init check build run py

init:
	git submodule update --init --recursive

check:
	@command -v tmux >/dev/null || (echo "tmux missing: sudo apt-get install tmux" && exit 1)
	@command -v uv >/dev/null || (echo "uv missing. Install: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
	@python3 -c "import gi" >/dev/null 2>&1 || (echo "python3-gi missing: sudo apt install python3-gi python3-gi-cairo libgirepository1.0-dev" && exit 1)
	@echo "ok"

py: init
	@cd deps/pano2kinematics && uv venv --python 3.10 --system-site-packages
	@cd deps/pano2kinematics && uv sync
	@deps/pano2kinematics/.venv/bin/python -c "import gi" >/dev/null 2>&1 || (echo "venv cannot import gi. Reinstall system packages and rerun make py." && exit 1)

build: init
	./scripts/build_stack.sh

run:
	./scripts/run_tmux.sh
