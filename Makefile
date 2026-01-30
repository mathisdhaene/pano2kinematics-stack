SHELL := /usr/bin/env bash

.PHONY: init check build run py

init:
	git submodule update --init --recursive

check:
	@command -v tmux >/dev/null || (echo "tmux missing: sudo apt-get install tmux" && exit 1)
	@command -v uv >/dev/null || (echo "uv missing. Install: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
	@echo "ok"

py: init
	@cd deps/pano2kinematics && uv sync

build: init
	./scripts/build_stack.sh

run:
	./scripts/run_tmux.sh
