#!/bin/bash

# Script to protect the main branch using GitHub CLI
# Requires GitHub CLI (gh) to be installed and authenticated

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed or not in PATH."
    echo "Please install it from https://cli.github.com/ and authenticate with 'gh auth login'"
    exit 1
fi

# Get the repository name from the remote URL
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(echo $REPO_URL | sed -n 's/.*github.com[:\/]\(.*\)\.git/\1/p')

echo "Setting up branch protection for main branch in repository: $REPO_NAME"

# Create branch protection rule for main branch
gh api \
  --method PUT \
  repos/$REPO_NAME/branches/main/protection \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  -f restrictions=null

if [ $? -eq 0 ]; then
    echo "Branch protection for main branch has been set up successfully."
    echo "The main branch now requires pull requests and at least one approval before merging."
else
    echo "Failed to set up branch protection. Please check your GitHub permissions."
    exit 1
fi
