# K8s Release

<table>
  <tr>
    <td valign="top" width="100">
      <img src="https://raw.githubusercontent.com/avkcode/k8s-release/refs/heads/main/favicon.svg"
           alt="K8s Release Logo"
           width="80">
    </td>
    <td valign="middle">
    Building Kubernetes using Kubernetes
    </td>
  </tr>
</table>

# Table of Contents
- [Rationale](#rationale)
  - [Project Build System](#project-build-system)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Targets](#targets)
    - [Variables](#variables)
  - [Build Examples](#build-examples)
    - [Perform a Simple Build](#perform-a-simple-build)
    - [Build RPM Packages](#build-rpm-packages)
    - [Build Both Debian and RPM Packages](#build-both-debian-and-rpm-packages)
    - [Build a Specific Component](#build-a-specific-component)
    - [Build Flannel with RPM Package Type](#build-flannel-with-rpm-package-type)
    - [Perform a Build Without Cache](#perform-a-build-without-cache)
    - [Use a Custom Kubernetes Version](#use-a-custom-kubernetes-version)
    - [Enable Kubernetes-Based Builds](#enable-kubernetes-based-builds)
    - [Use ARM64 Builder](#use-arm64-builder)
  - [Requirements](#requirements)
    - [Tools](#tools)
      - [Docker](#docker)
      - [Docker Buildx](#docker-buildx)
      - [Docker Compose](#docker-compose)
      - [Verification](#verification)
  - [Kubernetes-Based Distributed Builds with Docker Buildx](#kubernetes-based-distributed-builds-with-docker-buildx)
    - [Overview](#overview)
    - [Docker Registry](#docker-registry)
    - [Prerequisites](#prerequisites-1)
    - [Create Namespace](#create-namespace)
    - [Create Buildx Instance](#create-buildx-instance)
    - [Append Additional Node](#append-additional-node)
    - [Multi-architecture builds](#multi-architecture-builds)
    - [Inspect Buildx Instance](#inspect-buildx-instance)
    - [Delete Buildx Instance](#delete-buildx-instance)
    - [Building Components](#building-components)
    - [Installing Packages](#installing-packages)

## Rationale

Keeping up with Kubernetes' rapid release cycle is a significant challenge, especially for platform builders who rely on Kubernetes as the foundation for their systems. Kubernetes releases a new version approximately every three months, each introducing new features, enhancements, and sometimes breaking changes.
To address this challenge, we decided to create a reusable template for building Kubernetes using Kubernetes itself as a build farm.

## Project Build System

This project uses a `Makefile` to automate build processes using Docker, Docker Compose, and Docker Buildx. The Makefile supports both local and Kubernetes-based distributed builds.

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

|Target|Description|
|---|---|
|`help`|Display this help message.|
|`build`|Perform a simple build using Docker Buildx.|
|`build-no-cache`|Perform a build without using the cache.|
|`check-tools`|Verify that Docker, Docker Compose, and Docker Buildx are installed and functional.|

### Variables

|Variable|Description|Default Value|
|---|---|---|
|`KUBE_BUILDER`|Enable Kubernetes-based distributed builds using Buildx. Set to `1` to enable, `0` to disable.|`0`|
|`KUBE_VERSION`|Kubernetes version to use for builds.|`v1.28.0`|
|`COMPOSE_DOCKER_CLI_BUILD`|Enable Docker CLI build. Set to `1` to enable.|`1`|
|`DOCKER_BUILDKIT`|Enable BuildKit for Docker builds. Set to `1` to enable.|`1`|

## Build Examples

### Perform a Simple Build

To perform a build using the default settings (Debian packages):
```bash
make build
```

### Build RPM Packages

To build RPM packages instead of Debian packages:
```bash
make build PACKAGE_TYPE=rpm
```

### Build Both Debian and RPM Packages

To build both Debian and RPM packages:
```bash
make build PACKAGE_TYPE=all
```

### Build a Specific Component

To build only a specific component (e.g., kubelet):
```bash
make build-kubelet
```

### Build Flannel with RPM Package Type

To build Flannel as an RPM package:
```bash
make build-flannel PACKAGE_TYPE=rpm
```

Example output:
```
calico                                    flanneld
calico_3.28.0_amd64.deb                   flanneld_0.26.4_amd64.deb
calico-felix                              kube-apiserver
calico-felix_3.28.0_amd64.deb             kube-apiserver_1.32.2_amd64.deb
calico-ipam                               kube-controller-manager
calico-ipam_3.28.0_amd64.deb              kube-controller-manager_1.32.2_amd64.deb
calico-kube-controllers                   kubectl
calico-kube-controllers_3.28.0_amd64.deb  kubectl_1.32.2_amd64.deb
calico-node                               kubelet
calico-node_3.28.0_amd64.deb              kubelet_1.32.2_amd64.deb
etcd                                      kube-proxy
etcd_3.5.9_amd64.deb                      kube-proxy_1.32.2_amd64.deb
etcdctl                                   kube-scheduler
etcdctl_3.5.9_amd64.deb                   kube-scheduler_1.32.2_amd64.deb
```

### Perform a Build Without Cache

To perform a build without using the cache:
```bash
make build-no-cache
```

### Use a Custom Kubernetes Version

To perform a build with a custom Kubernetes version:
```bash
make build KUBE_VERSION=v1.33.0
```

### Enable Kubernetes-Based Builds

To enable Kubernetes-based distributed builds:
```bash
make build KUBE_BUILDER=1
```

### Use ARM64 Builder

To use the ARM64 builder for cross-platform builds:
```bash
make build KUBE_BUILDER_ARM64=1
```

Notes

- The output directory is automatically created if it does not exist.
- Build duration is displayed at the end of each build process.

---

## Requirements

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

---

# Kubernetes-Based Distributed Builds with Docker Buildx

Docker Buildx is a powerful extension of Docker's build capabilities, enabling advanced features such as multi-platform builds and distributed builds. When combined with Kubernetes, Buildx allows you to leverage a Kubernetes cluster as a distributed build farm, significantly improving build performance and scalability.

## Overview

This build system supports building and packaging the following components:

1. **Kubernetes Core Components**:
   - kube-apiserver
   - kube-controller-manager
   - kube-scheduler
   - kube-proxy
   - kubelet
   - kubectl

2. **Container Networking Interface (CNI) Plugins**:
   - Flannel (v0.26.4)
   - Calico (v3.28.0)

3. **Distributed Key-Value Store**:
   - etcd (v3.5.9)

All components are packaged as Debian (.deb) packages for easy installation and management on Debian-based systems.

## Docker Registry

A Docker Registry is a storage and distribution system for Docker images. It allows you to store, manage, and share container images within your environment. When using Docker Buildx for distributed builds, a Docker Registry is often used as a central repository to store intermediate and final build artifacts. This is especially important in Kubernetes-based distributed builds, where multiple nodes in the cluster need access to the same images.

[Buildx Kubernetes driver](https://docs.docker.com/build/builders/drivers/kubernetes)

## Prerequisites

Kubernetes Cluster:
Ensure you have a running Kubernetes cluster (e.g., Minikube, Kind, or a production-grade cluster like GKE, EKS, or AKS).

Install and configure kubectl, the Kubernetes command-line tool. Verify it works by running:
```
kubectl version --client
```
Ensure the buildx namespace exists. If it doesn't, create it:
```
kubectl create namespace buildx
```

## Create Namespace

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: buildx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: buildx
spec:
  type: ClusterIP
  selector:
    app: docker-registry
  ports:
  - port: 5000
    targetPort: 5000
```

Use kubectl apply to deploy the Docker Registry:
```
kubectl apply -f docker-registry.yaml
```
Output:
```
deployment.apps/docker-registry created
service/docker-registry created
```

Verify the Deployment:
Check if the Docker Registry is running:
```
kubectl get pods -n buildx
```

Output (example):
```
NAME                               READY   STATUS    RESTARTS   AGE
docker-registry-7c8b5c6c5d-abcde   1/1     Running   0          30s
```

Verify the Service:
Check if the service is created and accessible:
```
kubectl get svc -n buildx
```

Output (example):
```
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
docker-registry   ClusterIP   10.96.123.45    <none>        5000/TCP   1m
```
## Create Buildx Instance

Create a new Buildx instance named `kube-build-farm` using the Kubernetes driver. This command sets up the instance with 2 replicas, CPU limits, and a custom configuration file. Ensure the `buildx` namespace exists before running this command.

```
docker buildx create \
    --platform amd64 \
    --name kube-build-farm \
    --driver kubernetes \
    --driver-opt loadbalance=random \
    --driver-opt replicas=2 \
    --driver-opt namespace=buildx \
    --driver-opt limits.cpu=1 \
    --config config-remote.toml \
    --bootstrap
```

## Append Additional Node

Append an additional node to the existing `kube-build-farm` Buildx instance. This command ensures the new node uses the same configuration and Kubernetes namespace.
```
docker buildx create \
    --platform amd64 \
    --append \
    --name <INSTANCE NAME> \
    --driver kubernetes \
    --driver-opt loadbalance=random \
    --driver-opt replicas=2 \
    --driver-opt namespace=buildx \
    --driver-opt limits.cpu=1 \
    --config config-remote.toml \
    --bootstrap
```
## Multi-architecture builds 

Performing multi-architecture builds (e.g., AMD64 and ARM64) using a single physical builder instance.

```bash
docker buildx create \
  --bootstrap \
  --name=<INSTANCE NAME> \
  --driver=kubernetes \
  --driver-opt=namespace=buildx,qemu.install=true
```

The qemu.install=true option is required for cross-architecture builds.

## Inspect Buildx Instance

Inspect the configuration and status of the `kube-build-farm` Buildx instance. This command provides details about the builder's setup and current state.
```
docker buildx inspect kube-build-farm
```

## Delete Buildx Instance

Steps to Manually Clean Up:
Locate Buildx Configuration Files  Docker Buildx stores its builder configurations in the following directory:
```
~/.docker/buildx
```

Check this directory for files related to kube-build-farm. You can list the files with:
```
ls -la ~/.docker/buildx
```

Remove the Corrupted Builder File  Identify and delete the file associated with kube-build-farm. For example:
```
rm ~/.docker/buildx/<corrupted-file>
```

Reset Buildx (Optional)  If the issue persists, you can reset Docker Buildx entirely by removing all builder instances and configurations:
```
docker buildx prune --all
```

This will remove all unused builders, containers, and cached data.
Restart Docker Daemon  Restart the Docker daemon to ensure all changes take effect:
```
systemctl restart docker
```

## Notes

- Ensure that Docker and Buildx are installed and properly configured before running the Buildx commands.
- The `config.toml` file must be present in the working directory for the `create` and `append` commands to work.
- These commands assume that the Kubernetes cluster is accessible and properly configured.
- The `buildx` namespace must exist in the Kubernetes cluster before running the Buildx commands. Use `kubectl create ns buildx` to create it if necessary.

## Building Components

After setting up your Kubernetes-based build farm, you can build individual components or all components at once:

```bash
# Build all components
make build

# Build only Calico
make build-calico

# Build only etcd
make build-etcd

# Build with custom versions
make build KUBE_VERSION=v1.29.0 CALICO_VERSION=v3.27.0
```

## Installing Packages

After building, you can install the Debian packages on your target systems:

```bash
# Install Calico components
sudo dpkg -i output/calico-node_3.28.0_amd64.deb
sudo dpkg -i output/calico-felix_3.28.0_amd64.deb
sudo dpkg -i output/calico_3.28.0_amd64.deb
sudo dpkg -i output/calico-ipam_3.28.0_amd64.deb
sudo dpkg -i output/calico-kube-controllers_3.28.0_amd64.deb

# Configure Calico (example)
sudo mkdir -p /etc/calico
sudo cat > /etc/calico/calico.env << EOF
NODENAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
CALICO_IPV4POOL_CIDR=192.168.0.0/16
EOF
```

