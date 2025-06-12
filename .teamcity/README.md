# TeamCity Configuration for Kubernetes Packages

This directory contains the TeamCity configuration files for building and publishing Kubernetes packages.

## Structure

- `settings.kts`: Main configuration file that defines the build configurations
- `pom.xml`: Maven project file for the TeamCity DSL

## Build Configurations

The project includes the following build configurations:

1. Build components:
   - Build kube-proxy
   - Build kubelet
   - Build etcd
   - Build kube-scheduler
   - Build kube-controller-manager
   - Build kube-apiserver
   - Build kubectl
   - Build flannel
   - Build calico
   - Build certificates

2. Publish Packages:
   - Collects artifacts from all build configurations
   - Creates package repositories (DEB and RPM)
   - Publishes packages to GitHub Packages

## Setup Instructions

1. Install TeamCity server and agent
2. Create a new project from version control
3. Point it to your repository
4. TeamCity will automatically detect the `.teamcity` directory and use the configuration

## Required Credentials

- GitHub Token: Create a token with `packages:write` permission and add it as a password parameter named `GITHUB_TOKEN`

## Customization

You can customize the build parameters in the TeamCity UI:
- Kubernetes version
- etcd version
- Flannel version
- Calico version
- Package type (DEB or RPM)
