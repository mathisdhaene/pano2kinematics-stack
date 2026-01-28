SHELL := /usr/bin/env bash

.PHONY: init check build run

init:
	git submodule update --init --recursive

check:
	@command -v tmux >/dev/null || (echo "tmux missing: sudo apt-get install tmux" && exit 1)
	@command -v conda >/dev/null || (echo "conda missing" && exit 1)
	@echo "ok"

build: init
	./scripts/build_stack.sh

run:
	./scripts/run_tmux.sh
