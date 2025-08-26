#!/bin/bash
# Publishes using a cache of the repo
# This script runs inside the Docker container

set -e

GITHUB_REPONAME="TalkingQuickly/talkingquickly.github.io"
DEPLOY_DIR="${DEPLOY_DIR:-/home/deploy/release}"

# Check if the deploy directory exists
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ Deploy directory doesn't exist at $DEPLOY_DIR. Run setup_fast_publish first"
    exit 1
fi

# Check if it's a git repository
if [ ! -d "$DEPLOY_DIR/.git" ]; then
    echo "❌ Deploy directory is not a git repository. Run setup_fast_publish first"
    exit 1
fi

echo "Building Jekyll site..."
bundle exec jekyll build

echo "Syncing files to deploy directory..."
rsync -avh _site/ "$DEPLOY_DIR" --delete --exclude '.git'

cd "$DEPLOY_DIR"

echo "Creating .nojekyll file..."
touch .nojekyll

echo "Committing changes..."
git add .

MESSAGE="Site updated at $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
git commit -m "$MESSAGE" || echo "No changes to commit"

echo "Pushing to GitHub..."
git push origin master --force

echo "✅ Site published successfully using fast publish!"