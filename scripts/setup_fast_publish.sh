#!/bin/bash
# Sets up folders for fast publishing
# This script runs inside the Docker container

set -e

GITHUB_REPONAME="TalkingQuickly/talkingquickly.github.io"
DEPLOY_DIR="${DEPLOY_DIR:-/home/deploy/release}"

# Check if directory already exists
if [ -d "$DEPLOY_DIR" ]; then
    echo "Deploy directory already exists at $DEPLOY_DIR"
    read -p "Do you want to remove it and re-clone? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing directory..."
        rm -rf "$DEPLOY_DIR"
    else
        echo "Keeping existing directory. Exiting."
        exit 0
    fi
fi

# Create parent directory if it doesn't exist
mkdir -p "$(dirname "$DEPLOY_DIR")"

echo "Cloning repository to $DEPLOY_DIR..."
git clone "git@github.com:${GITHUB_REPONAME}.git" "$DEPLOY_DIR"

cd "$DEPLOY_DIR"

echo "Checking out master branch..."
git checkout master

echo "✅ Fast publish setup complete!"
echo "You can now use publish_fast to publish quickly"