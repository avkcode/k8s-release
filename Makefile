.DEFAULT_GOAL := help

# Ensure the output directory exists
all: $(shell mkdir -p output)

# Use Kubernetes as the builder backend via Buildx
# Set to 1 to enable Kubernetes-based distributed builds using Buildx.
# Set to 0 to disable Kubernetes and use the default Docker builder.
KUBE_BUILDER ?= 0

# Define the Kubernetes version to use
KUBE_VERSION ?= v1.32.2

# Define the etcd version to use
ETCD_VERSION ?= v3.5.9

# Help target: Displays available targets and variables
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  help                    Display this help message"
	@echo "  build                   Perform a simple build using Buildx"
	@echo "  build-no-cache          Perform a simple build using Buildx without cache"
	@echo "  archive                 Create a git archive with branch and commit in the name"
	@echo "  bundle                  Create a git bundle with branch and commit in the name"
	@echo "  clean                   Clean up generated files"
	@echo ""
	@echo "Variables:"
	@echo "  KUBE_BUILDER            Use Kubernetes to build images (default: 0, set to 1 to enable)"
	@echo "  KUBE_VERSION            Kubernetes version to use (default: v1.32.2)"
	@echo "  ETCD_VERSION            Etcd version to use (default: v3.5.9)"
	@echo "  COMPOSE_DOCKER_CLI_BUILD Enable Docker CLI build (set to 1)"
	@echo "  DOCKER_BUILDKIT          Enable BuildKit for Docker builds (set to 1)"
	@echo ""

# Check if required tools are installed and functional
check-tools:
	@echo "Checking if required tools are installed..."
	@command -v docker >/dev/null 2>&1 || { echo >&2 "Error: Docker is not installed or not in PATH."; exit 1; }
	@docker --version >/dev/null 2>&1 || { echo >&2 "Error: Docker is not functioning correctly."; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo >&2 "Error: Docker Compose is not installed or not in PATH."; exit 1; }
	@docker-compose --version >/dev/null 2>&1 || { echo >&2 "Error: Docker Compose is not functioning correctly."; exit 1; }
	@docker buildx version >/dev/null 2>&1 || { echo >&2 "Error: Docker Buildx is not installed or not functioning correctly."; exit 1; }
	@echo "All required tools are installed and functional."

# Define BUILD_INFO to calculate and display build duration
define BUILD_INFO
    @echo "Build completed at: $$(date '+%Y-%m-%d %H:%M:%S')"
    @echo "Total build time: $$(($$(date +%s) - $(START_TIME))) seconds"
endef

# Switch to the appropriate Buildx builder based on KUBE_BUILDER
switch-builder:
ifeq ($(KUBE_BUILDER),1)
	@echo "Switching to Kubernetes Buildx builder..."
	@docker buildx use kube-build-farm || { echo >&2 "Error: Kubernetes Buildx builder not found."; exit 1; }
else
	@echo "Switching to default Buildx builder..."
	@docker buildx use default
endif

# If KUBE_BUILDER is set to 1, use buildx Kubernetes build farm
build: check-tools switch-builder
	@echo "Starting simple build process..."
	@$(eval START_TIME := $(shell date +%s))
	@KUBE_VERSION=$(KUBE_VERSION) ETCD_VERSION=$(ETCD_VERSION) COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up --build
	@$(BUILD_INFO)

# Perform a build without using the cache
build-no-cache: check-tools switch-builder
	@echo "Starting build process without cache..."
	@$(eval START_TIME := $(shell date +%s))
	@KUBE_VERSION=$(KUBE_VERSION) ETCD_VERSION=$(ETCD_VERSION) COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up --build --no-cache
	@$(BUILD_INFO)

# Variables
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT := $(shell git rev-parse --short HEAD)
BUILD_INFO := build-info.txt

# Target: Create git archive
.PHONY: archive
archive: $(BUILD_INFO)
	@echo "Creating git archive..."
	git archive --format=tar.gz --output=archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz HEAD
	@echo "Archive created: archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz"

# Target: Create git bundle
.PHONY: bundle
bundle: $(BUILD_INFO)
	@echo "Creating git bundle..."
	git bundle create bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle --all
	@echo "Bundle created: bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle"

# Generate build-info.txt
$(BUILD_INFO):
	@echo "Generating build-info.txt..."
	@echo "Branch: $(GIT_BRANCH)" > $(BUILD_INFO)
	@echo "Commit: $(GIT_COMMIT)" >> $(BUILD_INFO)
	@echo "Build Date: $(shell date)" >> $(BUILD_INFO)

# Clean up generated files
.PHONY: clean
clean:
	rm -f $(BUILD_INFO) archive-*.tar.gz bundle-*.bundle
