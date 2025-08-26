#!/bin/bash
# Sets up folders for fast publishing
# This script runs inside the Docker container

set -e

GITHUB_REPONAME="TalkingQuickly/talkingquickly.github.io"
DEPLOY_DIR="${DEPLOY_DIR:-/home/deploy/release}"

# Check if directory already exists
if [ -d "$DEPLOY_DIR" ]; then
    echo "Deploy directory already exists at $DEPLOY_DIR"
    
    # Check if it's a git repository
    if [ -d "$DEPLOY_DIR/.git" ]; then
        echo "Existing git repository found."
        read -p "Do you want to reset it? This will pull latest from master. (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Resetting existing repository..."
            cd "$DEPLOY_DIR"
            
            # Reset any local changes
            git reset --hard HEAD
            git clean -fd
            
            # Fetch and reset to origin/master
            echo "Fetching latest from origin..."
            git fetch origin
            git checkout master
            git reset --hard origin/master
            
            echo "✅ Repository reset to latest master!"
            exit 0
        else
            echo "Keeping existing repository. Exiting."
            exit 0
        fi
    else
        # Directory exists but is not a git repo
        echo "Directory exists but is not a git repository."
        echo "Attempting to clear directory contents..."
        
        # Try to remove contents instead of the directory itself
        cd "$DEPLOY_DIR"
        rm -rf ..?* .[!.]* * 2>/dev/null || true
        cd -
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