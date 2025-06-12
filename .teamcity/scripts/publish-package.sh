#!/bin/bash

# Script to publish a package to GitHub Packages from TeamCity
# Usage: publish-package.sh <package-file> <package-type> <github-token>

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <package-file> <package-type> <github-token>"
    exit 1
fi

PACKAGE_FILE=$1
PACKAGE_TYPE=$2
GITHUB_TOKEN=$3

# Get repository information
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(echo $REPO_URL | sed -n 's/.*github.com[:\/]\(.*\)\.git/\1/p')

# Extract package name and version
PACKAGE_NAME=$(basename $PACKAGE_FILE)
PACKAGE_VERSION=$(echo $PACKAGE_NAME | grep -oP '(?<=_)[0-9]+\.[0-9]+\.[0-9]+(?=_)')

if [ -z "$PACKAGE_VERSION" ]; then
    # Try to extract from git tag
    PACKAGE_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
    PACKAGE_VERSION="${PACKAGE_VERSION#v}"
fi

echo "Publishing $PACKAGE_NAME (version $PACKAGE_VERSION) to GitHub Packages"

# Upload the package to GitHub Packages
ORG_NAME=$(echo $REPO_NAME | cut -d '/' -f 1)

curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$PACKAGE_FILE" \
  "https://api.github.com/orgs/$ORG_NAME/packages/generic/kubernetes-packages/$PACKAGE_VERSION/$PACKAGE_NAME"

if [ $? -eq 0 ]; then
    echo "Successfully published $PACKAGE_NAME to GitHub Packages"
else
    echo "Failed to publish $PACKAGE_NAME to GitHub Packages"
    exit 1
fi
