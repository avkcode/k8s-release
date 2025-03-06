Kubernetes-Based Distributed Builds with Docker Buildx

Docker Buildx is a powerful extension of Docker's build capabilities, enabling advanced features such as multi-platform builds and distributed builds. When combined with Kubernetes, Buildx allows you to leverage a Kubernetes cluster as a distributed build farm, significantly improving build performance and scalability.

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
