# =============================================================================
# LYVOXA MAKEFILE - BUILD AUTOMATION & QUALITY CHECKS
# =============================================================================
# Optimized build automation and quality validation for Lyvoxa system monitor
# Author: rezky_nightky

# Configuration
PROJECT_NAME := lyvoxa
CARGO := cargo
TARGET := x86_64-unknown-linux-gnu
JOBS := 3

# Override system MAKEFLAGS for consistent 3-core builds
export MAKEFLAGS := -j$(JOBS)

# Directories
TARGET_DIR := target
RELEASE_DIR := $(TARGET_DIR)/$(TARGET)/release
DEBUG_DIR := $(TARGET_DIR)/$(TARGET)/debug

# Binaries
RELEASE_BIN := $(RELEASE_DIR)/$(PROJECT_NAME)
DEBUG_BIN := $(DEBUG_DIR)/$(PROJECT_NAME)
SIMPLE_RELEASE_BIN := $(RELEASE_DIR)/$(PROJECT_NAME)-simple
SIMPLE_DEBUG_BIN := $(DEBUG_DIR)/$(PROJECT_NAME)-simple

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# HELP TARGET
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Lyvoxa Build System - $(VERSION)$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  Project: $(PROJECT_NAME)"
	@echo "  Version: $(VERSION)"
	@echo "  Target:  $(TARGET)"
	@echo "  Jobs:    $(MAX_JOBS) (CPU core limit)"

# =============================================================================
# BUILD TARGETS
# =============================================================================

.PHONY: debug
debug: ## Build debug version (fast compilation)
	@echo "$(BLUE)[BUILD]$(NC) Building debug version with $(MAX_JOBS) cores..."
	$(CARGO) build --jobs $(MAX_JOBS) --target $(TARGET)
	@echo "$(GREEN)[SUCCESS]$(NC) Debug build completed!"
	@echo "$(BLUE)[INFO]$(NC) Binary: $(DEBUG_BIN)"

.PHONY: release
release: ## Build optimized release version
	@echo "$(BLUE)[BUILD]$(NC) Building release version with $(MAX_JOBS) cores..."
	$(CARGO) build --release --jobs $(MAX_JOBS) --target $(TARGET)
	@echo "$(GREEN)[SUCCESS]$(NC) Release build completed!"
	@echo "$(BLUE)[INFO]$(NC) Binary: $(RELEASE_BIN)"
	@if [ -f "$(RELEASE_BIN)" ]; then \
		echo "$(BLUE)[INFO]$(NC) Binary size: $$(du -h $(RELEASE_BIN) | cut -f1)"; \
	fi

.PHONY: release-debug
release-debug: ## Build release with debug info for profiling
	@echo "$(BLUE)[BUILD]$(NC) Building release with debug info..."
	$(CARGO) build --profile release-with-debug --jobs $(MAX_JOBS) --target $(TARGET)
	@echo "$(GREEN)[SUCCESS]$(NC) Release with debug build completed!"

.PHONY: all
all: check debug release test ## Build everything and run tests
	@echo "$(GREEN)[SUCCESS]$(NC) Full build cycle completed!"

# =============================================================================
# TESTING TARGETS
# =============================================================================

.PHONY: test
test: ## Run all tests
	@echo "$(BLUE)[TEST]$(NC) Running tests with $(MAX_JOBS) cores..."
	$(CARGO) test --jobs $(MAX_JOBS) --target $(TARGET)
	@echo "$(GREEN)[SUCCESS]$(NC) All tests passed!"

.PHONY: test-release
test-release: ## Run tests in release mode
	@echo "$(BLUE)[TEST]$(NC) Running tests in release mode..."
	$(CARGO) test --release --jobs $(MAX_JOBS) --target $(TARGET)

.PHONY: bench
bench: ## Run benchmarks
	@echo "$(BLUE)[BENCH]$(NC) Running benchmarks..."
	$(CARGO) bench --jobs $(MAX_JOBS) --target $(TARGET)

# =============================================================================
# CODE QUALITY TARGETS
# =============================================================================

.PHONY: check
check: fmt-check clippy ## Run all code quality checks

.PHONY: clippy
clippy: ## Run Clippy linter
	@echo "$(BLUE)[LINT]$(NC) Running Clippy..."
	$(CARGO) clippy --target $(TARGET) -- -D warnings
	@echo "$(GREEN)[SUCCESS]$(NC) Clippy checks passed!"

.PHONY: fmt
fmt: ## Format code
	@echo "$(BLUE)[FORMAT]$(NC) Formatting code..."
	$(CARGO) fmt
	@echo "$(GREEN)[SUCCESS]$(NC) Code formatted!"

.PHONY: fmt-check
fmt-check: ## Check code formatting
	@echo "$(BLUE)[FORMAT]$(NC) Checking code formatting..."
	$(CARGO) fmt --check
	@echo "$(GREEN)[SUCCESS]$(NC) Code formatting is correct!"

.PHONY: audit
audit: ## Audit dependencies for security vulnerabilities
	@echo "$(BLUE)[AUDIT]$(NC) Auditing dependencies..."
	$(CARGO) audit
	@echo "$(GREEN)[SUCCESS]$(NC) No security vulnerabilities found!"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(BLUE)[CLEAN]$(NC) Cleaning build artifacts..."
	$(CARGO) clean
	@echo "$(GREEN)[SUCCESS]$(NC) Build artifacts cleaned!"

.PHONY: clean-all
clean-all: clean ## Clean everything
	@echo "$(GREEN)[SUCCESS]$(NC) Everything cleaned!"

.PHONY: deps
deps: ## Update dependencies
	@echo "$(BLUE)[DEPS]$(NC) Updating dependencies..."
	$(CARGO) update
	@echo "$(GREEN)[SUCCESS]$(NC) Dependencies updated!"

.PHONY: outdated
outdated: ## Check for outdated dependencies
	@echo "$(BLUE)[DEPS]$(NC) Checking for outdated dependencies..."
	$(CARGO) outdated

.PHONY: tree
tree: ## Show dependency tree
	@echo "$(BLUE)[DEPS]$(NC) Dependency tree:"
	$(CARGO) tree --target $(TARGET)

# =============================================================================
# INSTALLATION TARGETS
# =============================================================================

.PHONY: install
install: release ## Install binaries to system
	@echo "$(BLUE)[INSTALL]$(NC) Installing binaries..."
	$(CARGO) install --path . --target $(TARGET) --jobs $(MAX_JOBS)
	@echo "$(GREEN)[SUCCESS]$(NC) Binaries installed!"

.PHONY: install-debug
install-debug: debug ## Install debug binaries to system
	@echo "$(BLUE)[INSTALL]$(NC) Installing debug binaries..."
	$(CARGO) install --path . --target $(TARGET) --jobs $(MAX_JOBS) --debug
	@echo "$(GREEN)[SUCCESS]$(NC) Debug binaries installed!"

# =============================================================================
# PERFORMANCE TARGETS
# =============================================================================

.PHONY: profile
profile: release-debug ## Profile the application
	@echo "$(BLUE)[PROFILE]$(NC) Running performance profile..."
	perf record --call-graph=dwarf $(RELEASE_DIR)/$(PROJECT_NAME)
	perf report

.PHONY: flamegraph
flamegraph: release-debug ## Generate flamegraph
	@echo "$(BLUE)[PROFILE]$(NC) Generating flamegraph..."
	$(CARGO) flamegraph --bin $(PROJECT_NAME) --target $(TARGET)

.PHONY: size
size: release ## Show binary size breakdown
	@echo "$(BLUE)[SIZE]$(NC) Binary size analysis:"
	@if [ -f "$(RELEASE_BIN)" ]; then \
		echo "Main binary: $$(du -h $(RELEASE_BIN) | cut -f1)"; \
		size $(RELEASE_BIN); \
	fi
	@if [ -f "$(SIMPLE_RELEASE_BIN)" ]; then \
		echo "Simple binary: $$(du -h $(SIMPLE_RELEASE_BIN) | cut -f1)"; \
		size $(SIMPLE_RELEASE_BIN); \
	fi

# =============================================================================
# CACHE TARGETS
# =============================================================================

.PHONY: sccache-stats
sccache-stats: ## Show sccache statistics
	@if command -v sccache >/dev/null 2>&1; then \
		echo "$(BLUE)[CACHE]$(NC) sccache statistics:"; \
		sccache --show-stats; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) sccache not installed"; \
	fi

.PHONY: sccache-zero
sccache-zero: ## Reset sccache statistics
	@if command -v sccache >/dev/null 2>&1; then \
		echo "$(BLUE)[CACHE]$(NC) Resetting sccache statistics..."; \
		sccache --zero-stats; \
		echo "$(GREEN)[SUCCESS]$(NC) sccache statistics reset!"; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) sccache not installed"; \
	fi

# =============================================================================
# CI/CD TARGETS
# =============================================================================

.PHONY: ci
ci: check test release ## Run CI pipeline
	@echo "$(GREEN)[CI]$(NC) CI pipeline completed successfully!"

.PHONY: cd
cd: ci ## Run CD pipeline
	@echo "$(GREEN)[CD]$(NC) CD pipeline completed successfully!"

# =============================================================================
# QUALITY ASSURANCE & PRE-COMMIT CHECKS
# =============================================================================

.PHONY: test-local
test-local: ## Run full local build test before commit/push
	@echo "$(BLUE)[TEST]$(NC) Running local build test..."
	./test-local.sh

.PHONY: pre-commit
pre-commit: ## Run full pre-commit quality checks
	@echo "$(BLUE)[QA]$(NC) Running comprehensive pre-commit checks..."
	./pre-commit.sh

.PHONY: pre-commit-quick
pre-commit-quick: ## Run quick pre-commit checks (no tests/audit)
	@echo "$(BLUE)[QA]$(NC) Running quick pre-commit checks..."
	./pre-commit.sh --quick

.PHONY: setup-hooks
setup-hooks: ## Setup Git pre-commit and pre-push hooks
	@echo "$(BLUE)[SETUP]$(NC) Installing Git hooks..."
	./lyvoxa-maintain.sh setup

.PHONY: update-deps
update-deps: ## Update all dependencies
	@echo "$(BLUE)[UPDATE]$(NC) Updating dependencies..."
	./lyvoxa-maintain.sh update-deps

.PHONY: show-version
show-version: ## Show current version
	./lyvoxa-maintain.sh version

.PHONY: maintain
maintain: ## Run maintenance tool (interactive)
	./lyvoxa-maintain.sh help

.PHONY: quality-full
quality-full: fmt-check clippy test audit ## Run all quality checks
	@echo "$(GREEN)[QA]$(NC) All quality checks passed!"

.PHONY: quality-quick
quality-quick: fmt-check clippy debug ## Run quick quality checks
	@echo "$(GREEN)[QA]$(NC) Quick quality checks passed!"

# =============================================================================
# ARCH LINUX PACKAGE BUILDING
# =============================================================================

.PHONY: arch-pkg
arch-pkg: ## Build Arch Linux source package
	@echo "$(BLUE)[PKG]$(NC) Building Arch Linux source package..."
	./build-arch-pkg.sh source

.PHONY: arch-pkg-clean
arch-pkg-clean: ## Clean Arch Linux package build artifacts
	@echo "$(BLUE)[PKG]$(NC) Cleaning package build artifacts..."
	./build-arch-pkg.sh clean

# =============================================================================
# PHONY DECLARATIONS
# =============================================================================

.PHONY: all debug release release-debug test test-release bench
.PHONY: check clippy fmt fmt-check audit
.PHONY: clean clean-all deps outdated tree
.PHONY: install install-debug
.PHONY: profile flamegraph size
.PHONY: sccache-stats sccache-zero
.PHONY: ci cd help
.PHONY: pre-commit pre-commit-quick setup-hooks quality-full quality-quick
.PHONY: arch-pkg arch-pkg-clean
