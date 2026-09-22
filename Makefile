# One entry point for every check, used by you, the pre-commit hook and CI alike.
# `make help` lists the targets.

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
export PATH := $(CURDIR)/.tools/bin:$(PATH)

# Minimum line coverage, per file, for libs/ and every Core/ folder.
COVERAGE_FLOOR ?= 90

.PHONY: help bootstrap check fmt fmt-check lint typecheck test coverage wow-api

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  make %-10s %s\n", $$1, $$2 }'

bootstrap: ## Install the pinned toolchain into .tools/ and enable the git hooks
	@tools/bootstrap

check: fmt-check lint typecheck coverage ## Everything CI runs: format, lint, types, tests + coverage
	@echo "all checks passed"

fmt: ## Format all Lua in place
	@stylua .

fmt-check: ## Fail if any Lua is not formatted
	@stylua --check .

lint: ## luacheck against Forever's generated API
	@luacheck --quiet .

typecheck: ## Lua language server diagnostics against the WoW API annotations
	@tools/typecheck

test: ## Run the busted specs
	@busted

coverage: ## Run the specs with coverage and enforce COVERAGE_FLOOR per file
	@rm -f luacov.stats.out luacov.report.out
	@busted --coverage
	@luacov
	@lua tools/coverage.lua $(COVERAGE_FLOOR)

wow-api: ## Regenerate tools/wow/forever_api.lua from the pinned Forever build
	@tools/gen-wow-api
