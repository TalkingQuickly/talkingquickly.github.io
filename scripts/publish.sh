#!/bin/bash
# Generate and publish blog to gh-pages (master branch)
# This script runs inside the Docker container

set -e

GITHUB_REPONAME="TalkingQuickly/talkingquickly.github.io"

echo "Building Jekyll site..."
bundle exec jekyll build

echo "Creating temporary directory for deployment..."
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Copying site to temporary directory..."
cp -r _site/. "$TMPDIR/"

cd "$TMPDIR"

echo "Initializing git repository..."
git init
git add .

MESSAGE="Site updated at $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
git commit -m "$MESSAGE"

echo "Adding remote and pushing to GitHub..."
git remote add origin "git@github.com:${GITHUB_REPONAME}.git"
git push origin master --force

echo "✅ Site published successfully!"