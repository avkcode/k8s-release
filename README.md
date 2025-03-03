# Project Build System

This project uses a `Makefile` to automate build processes using Docker, Docker Compose, and Docker Buildx. The Makefile supports both local and Kubernetes-based distributed builds.

---

## Prerequisites

Before using the Makefile, ensure the following tools are installed and functional:

- **Docker**: Required for containerization.
- **Docker Compose**: Required for multi-container Docker applications.
- **Docker Buildx**: Required for advanced build features, including Kubernetes-based builds.

To verify that all tools are installed and working, run:

```bash
make check-tools
```

## Usage

### Targets

The following targets are available in the Makefile:

Target	Description
help	Display this help message.
build	Perform a simple build using Docker Buildx.
build-no-cache	Perform a build without using the cache.
check-tools	Verify that Docker, Docker Compose, and Docker Buildx are installed and functional.
Variables

The following variables can be customized:

Variable	Description	Default Value
KUBE_BUILDER	Enable Kubernetes-based distributed builds using Buildx. Set to 1 to enable, 0 to disable.	0
KUBE_VERSION	Kubernetes version to use for builds.	v1.28.0
COMPOSE_DOCKER_CLI_BUILD	Enable Docker CLI build. Set to 1 to enable.	1
DOCKER_BUILDKIT	Enable BuildKit for Docker builds. Set to 1 to enable.	1


## Perform a Simple Build

To perform a build using the default settings:
```
make build
```

Perform a Build Without Cache

To perform a build without using the cache:
```
make build-no-cache
```

Use a Custom Kubernetes Version

To perform a build with a custom Kubernetes version (e.g., v1.29.0):
```
make build KUBE_VERSION=v1.29.0
```
Enable Kubernetes-Based Builds

To enable Kubernetes-based distributed builds:

```
make build KUBE_BUILDER=1
```

Notes

- The output directory is automatically created if it does not exist.
- Build duration is displayed at the end of each build process.

---

# Requirements

To use this project and its build system, the following tools must be installed and properly configured on your system:

## Tools

### Docker
Docker is required for containerization. It allows you to build, run, and manage containers for the application.
Installation: Follow the official Docker installation guide for your operating system.
Verification: Ensure Docker is installed and functional by running:
```
docker --version
```

### Docker Buildx
Docker Buildx is an extended build feature that supports advanced build capabilities, such as multi-platform builds and Kubernetes-based distributed builds.
Installation: Docker Buildx is included with Docker Desktop by default. For Linux, ensure Docker is installed and Buildx is enabled.
Verification: Check if Buildx is installed and working by running:
```
docker buildx version
```

### Docker Compose
Docker Compose is used to define and manage multi-container Docker applications. It simplifies the process of building and running containers.
Installation: Follow the official Docker Compose installation guide.
Verification: Ensure Docker Compose is installed and functional by running:
```
docker-compose --version
```

### Verification

To verify that all required tools are installed and functioning correctly, run the following command:
```
make check-tools
```

This command checks for the presence and functionality of Docker, Docker Buildx, and Docker Compose. If any tool is missing or not working, the command will provide an error message with details.

### Notes

Ensure that Docker is running and properly configured on your system before using the Makefile.
If you plan to use Kubernetes-based distributed builds (enabled by setting KUBE_BUILDER=1), ensure that your Kubernetes cluster is properly configured and accessible.
The check-tools target in the Makefile is a convenient way to validate your setup before proceeding with builds.
