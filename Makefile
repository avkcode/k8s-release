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

KUBE_GIT_URL ?= https://github.com/kubernetes/kubernetes.git

# Define the Flannel version to use
FLANNEL_VERSION ?= v0.26.4
FLANNEL_GIT_URL ?= https://github.com/flannel-io/flannel.git

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
	@echo "  release                 Create a Git tag and release on GitHub"
	@echo ""
	@echo "Variables:"
	@echo "  FLANNEL_GIT_URL         Flannel Git repository URL (default: https://github.com/flannel-io/flannel.git)"
	@echo "  FLANNEL_VERSION         Flannel version to use (default: v0.26.4)"
	@echo "  KUBE_GIT_URL            Kubernetes Git repository URL (default: https://github.com/kubernetes/kubernetes.git)"
	@echo "  KUBE_BUILDER            Use Kubernetes to build images (default: 0, set to 1 to enable)"
	@echo "  KUBE_BUILDER_ARM64      Use Kubernetes ARM64 builder (default: 0, set to 1 to enable)"
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

# Switch to the appropriate Buildx builder based on KUBE_BUILDER or KUBE_BUILDER_ARM64
switch-builder:
ifeq ($(KUBE_BUILDER_ARM64),1)
	@echo "Switching to Kubernetes ARM64 Buildx builder..."
	@docker buildx use kube-build-farm-arm64 || { echo >&2 "Error: Kubernetes ARM64 Buildx builder not found."; exit 1; }
else ifeq ($(KUBE_BUILDER),1)
	@echo "Switching to Kubernetes Buildx builder..."
	@docker buildx use kube-build-farm || { echo >&2 "Error: Kubernetes Buildx builder not found."; exit 1; }
else
	@echo "Switching to default Buildx builder..."
	@docker buildx use default
endif

# Define the default platform based on $KUBE_BUILDER
ifeq ($(KUBE_BUILDER_ARM64),1)
    DOCKER_DEFAULT_PLATFORM := linux/arm64
else
    DOCKER_DEFAULT_PLATFORM := linux/amd64
endif

# Multi-line variable for docker-compose arguments
define DOCKER_ARGS
    KUBE_VERSION=$(KUBE_VERSION) \
    KUBE_GIT_URL=$(KUBE_GIT_URL) \
    ETCD_VERSION=$(ETCD_VERSION) \
    COMPOSE_DOCKER_CLI_BUILD=1 \
    DOCKER_BUILDKIT=1 \
    FLANNEL_GIT_URL=$(FLANNEL_GIT_URL) \
    FLANNEL_VERSION=$(FLANNEL_VERSION) \
    DOCKER_DEFAULT_PLATFORM=$(DOCKER_DEFAULT_PLATFORM) 
endef

# If KUBE_BUILDER is set to 1, use buildx Kubernetes build farm
build: check-tools switch-builder
	@echo "Starting simple build process..."
	@$(eval START_TIME := $(shell date +%s))
	$(DOCKER_ARGS) docker-compose up --build
	@$(BUILD_INFO)

# Perform a build without using the cache
build-no-cache: check-tools switch-builder
	@echo "Starting build process without cache..."
	@$(eval START_TIME := $(shell date +%s))
	$(DOCKER_ARGS) docker-compose up --build --no-cache
	@$(BUILD_INFO)

# Variables
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Target: Create git archive
.PHONY: archive
archive:
	@echo "Creating git archive..."
	git archive --format=tar.gz --output=archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz HEAD
	@echo "Archive created: archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz"

# Target: Create git bundle
.PHONY: bundle
bundle:
	@echo "Creating git bundle..."
	git bundle create bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle --all
	@echo "Bundle created: bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle"

# Clean up generated files
.PHONY: clean
clean:
	@rm -f archive-*.tar.gz bundle-*.bundle

# Target: Create a Git tag and release on GitHub
.PHONY: release
release:
	@echo "Creating Git tag and releasing on GitHub..."
	@read -p "Enter the version number (e.g., v1.0.0): " version; \
	git tag -a $$version -m "Release $$version"; \
	git push origin $$version; \
	gh release create $$version --generate-notes
	@echo "Release $$version created and pushed to GitHub."
