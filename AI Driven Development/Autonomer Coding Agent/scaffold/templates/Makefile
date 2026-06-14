# Makefile — die drei Verben, die der Agent kennt: setup / check / fix.
# `make check` ist das objektive Done-Gate; der Orchestrator faehrt es im Verify-Schritt selbst.
.PHONY: setup check fix

setup:
	uv sync
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg

check:
	uv run pre-commit run --all-files
	uv run pytest

fix:
	uv run ruff check --fix .
	uv run ruff format .
