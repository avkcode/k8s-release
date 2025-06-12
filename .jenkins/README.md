# Jenkins CI/CD for Kubernetes Packages

This directory contains the Jenkins configuration for building and publishing Kubernetes packages in enterprise environments.

## Overview

The Jenkins setup includes:

- Dockerfile for creating a custom Jenkins image with necessary tools
- Docker Compose configuration for running Jenkins with Docker support
- Scripts for publishing packages
- Jenkinsfile pipeline for building all components

## Jenkinsfile Pipeline

The Jenkinsfile defines a parameterized pipeline that:

- Builds all Kubernetes components in parallel
- Collects artifacts from all builds
- Creates package repositories (DEB and RPM)
- Optionally publishes packages to GitHub Packages (when on main branch)

## Setting Up Jenkins

To set up Jenkins for this project:

1. Navigate to the `.jenkins` directory
2. Build and start the Jenkins container:
   ```bash
   cd .jenkins
   docker-compose up -d
   ```
3. Access Jenkins at http://localhost:8080
4. Create a new pipeline job using the Jenkinsfile from this repository
5. Configure GitHub credentials for package publishing

## Pipeline Parameters

The Jenkins pipeline supports the following parameters:

- `KUBE_VERSION`: Kubernetes version to build (default: v1.32.2)
- `ETCD_VERSION`: etcd version to build (default: v3.5.9)
- `FLANNEL_VERSION`: Flannel version to build (default: v0.26.4)
- `CALICO_VERSION`: Calico version to build (default: v3.28.0)
- `PACKAGE_TYPE`: Package type to build (choices: deb, rpm)

## Required Credentials

For the pipeline to publish packages to GitHub Packages, you need to configure a credential in Jenkins:

1. Go to Jenkins > Manage Jenkins > Manage Credentials
2. Add a new Secret text credential with ID `github-token`
3. Use a GitHub Personal Access Token with `packages:write` permission

## Build Artifacts

The pipeline produces the following artifacts:

- Individual component packages (DEB or RPM)
- Complete package repositories for easy installation
