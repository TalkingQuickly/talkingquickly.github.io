# Docker Execution Scripts

This directory contains the actual scripts that run inside Docker containers. These scripts should **not** be executed directly on the host machine.

## Scripts

- `publish.sh` - Builds and publishes the site to GitHub Pages
- `publish_fast.sh` - Publishes using a cached repository for faster deployment
- `setup_fast_publish.sh` - Sets up the cached repository for fast publishing

## Usage

These scripts are called by the wrapper scripts in `/bin`. Always use the `/bin` scripts:

```bash
# Correct usage (from project root):
./bin/publish
./bin/publish_fast
./bin/setup_fast_publish

# Incorrect (don't run directly):
./scripts/publish.sh  # Won't work correctly outside Docker
```

## Docker Context

When running inside Docker:
- Working directory: `/home/deploy/app`
- User: `deploy`
- Fast deploy cache: `/home/deploy/release` (Docker volume)
- SSH keys: Mounted from host at `/home/deploy/.ssh`