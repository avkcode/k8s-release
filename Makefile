# Default target: Display help message
.DEFAULT_GOAL := help

# Ensure the output directory exists
all: $(shell mkdir -p output)

# Help target: Displays available targets and variables
help: ## Display this help message
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  help                    Display this help message"
	@echo "  create-buildx-instance  Create the initial kube-build-farm Buildx instance"
	@echo "  append-buildx-node      Append additional nodes to the kube-build-farm Buildx instance"
	@echo "  inspect-buildx-instance Inspect the configuration and status of the kube-build-farm instance"
	@echo "  clean-buildx-instance   Remove the kube-build-farm Buildx instance for cleanup"
	@echo ""
	@echo "Variables:"
	@echo "  KUBE_VERSION            Kubernetes version to use (default: v1.28.0)"
	@echo "  COMPOSE_DOCKER_CLI_BUILD Enable Docker CLI build (set to 1)"
	@echo "  DOCKER_BUILDKIT          Enable BuildKit for Docker builds (set to 1)"
	@echo ""

# Target to build with a timer and metadata logging
build-with-timer:
	@echo "Starting build process..."
	@START_TIME=$$(date +%s); \
	GIT_COMMIT=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	BUILD_TIMESTAMP=$$(date +"%Y-%m-%d %H:%M:%S"); \
	echo "Build started at: $$BUILD_TIMESTAMP"; \
	echo "Git commit: $$GIT_COMMIT"; \
	KUBE_VERSION=v1.28.0 COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up --build; \
	END_TIME=$$(date +%s); \
	BUILD_DURATION=$$((END_TIME - START_TIME)); \
	echo "Build completed at: $$(date +"%Y-%m-%d %H:%M:%S")"; \
	echo "Total build time: $$BUILD_DURATION seconds"; \
	echo "Build details:" > output/build_info.txt; \
	echo "  Timestamp: $$BUILD_TIMESTAMP" >> output/build_info.txt; \
	echo "  Git Commit: $$GIT_COMMIT" >> output/build_info.txt; \
	echo "  Duration: $$BUILD_DURATION seconds" >> output/build_info.txt; \
	echo "Build info saved to output/build_info.txt"


# Default target to create the kube-build-farm instance
create-buildx-instance:
	@echo "Creating Buildx instance 'kube-build-farm'..."
	@docker buildx create \
		--platform amd64 \
		--name kube-build-farm \
		--driver kubernetes \
		--driver-opt loadbalance=random \
		--driver-opt replicas=2 \
		--driver-opt namespace=buildx \
		--driver-opt limits.cpu=1 \
		--config ./config.toml \
		--bootstrap
	@echo "Buildx instance 'kube-build-farm' created successfully."

# Target to append additional nodes to the kube-build-farm instance
append-buildx-node:
	@echo "Appending additional node to Buildx instance 'kube-build-farm'..."
	@docker buildx create \
		--platform amd64 \
		--append \
		--name kube-build-farm \
		--driver kubernetes \
		--driver-opt loadbalance=random \
		--driver-opt replicas=2 \
		--driver-opt namespace=buildx \
		--driver-opt limits.cpu=1 \
		--config ./config.toml \
		--bootstrap
	@echo "Additional node appended to Buildx instance 'kube-build-farm'."

# Target to inspect the kube-build-farm instance
inspect-buildx-instance:
	@echo "Inspecting Buildx instance 'kube-build-farm'..."
	@docker buildx inspect kube-build-farm
	@echo "Inspection completed."

# Clean up the Buildx instance (optional)
clean-buildx-instance:
	@echo "Removing Buildx instance 'kube-build-farm'..."
	@docker buildx rm kube-build-farm || true
	@echo "Buildx instance 'kube-build-farm' removed."
