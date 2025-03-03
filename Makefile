.DEFAULT_GOAL := help

# Ensure the output directory exists
all: $(shell mkdir -p output)

# Use Kubernetes as the builder backend via Buildx
# Set to 1 to enable Kubernetes-based distributed builds using Buildx.
# Set to 0 to disable Kubernetes and use the default Docker builder.
KUBE_BUILDER ?= 0

# Help target: Displays available targets and variables
help: ## Display this help message
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  help                    Display this help message"
	@echo "  build                   Perform a simple build using Buildx"
	@echo "  build-no-cache          Perform a simple build using Buildx without cache"
	@echo ""
	@echo "Variables:"
	@echo "  KUBE_BUILDER            Use Kubernetes to build images (default: 1, set to 0 to disable)"
	@echo "  KUBE_VERSION            Kubernetes version to use (default: v1.28.0)"
	@echo "  COMPOSE_DOCKER_CLI_BUILD Enable Docker CLI build (set to 1)"
	@echo "  DOCKER_BUILDKIT          Enable BuildKit for Docker builds (set to 1)"
	@echo ""

# Target to check if required tools are installed and functional
check-tools: ## Check if docker, docker-compose, and buildx are installed and functional
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

# Perform a simple build using Buildx
build: ## Perform a simple build using Buildx
	@echo "Starting simple build process..."
	@$(eval START_TIME := $(shell date +%s))
	@KUBE_VERSION=v1.28.0 COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build \
		$(if $(filter 1,$(KUBE_BUILDER)),--builder=kube-build-farm,)
	@$(BUILD_INFO)

# Perform a build without using the cache
build-no-cache: ## Perform a build without using the cache
	@echo "Starting build process without cache..."
	@$(eval START_TIME := $(shell date +%s))
	@KUBE_VERSION=v1.28.0 COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build \
 		$(if $(filter 1,$(KUBE_BUILDER)),--builder=kube-build-farm,) --no-cache
	@$(BUILD_INFO)
