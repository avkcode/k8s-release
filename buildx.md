## Create Namespace

Ensure the `buildx` namespace exists in your Kubernetes cluster. The Buildx commands rely on this namespace to deploy resources. Run the following command to create the namespace if it does not already exist.

```
kubectl create ns buildx
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
    --name kube-build-farm \
    --driver kubernetes \
    --driver-opt loadbalance=random \
    --driver-opt replicas=2 \
    --driver-opt namespace=buildx \
    --driver-opt limits.cpu=1 \
    --config config-remote.toml \
    --bootstrap
```

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
