# Blog Management Scripts

This directory contains wrapper scripts that execute commands inside Docker containers. This ensures consistent environments without requiring local installation of Jekyll or other dependencies.

## Architecture

- Scripts in `/bin` are simple wrappers that call `docker compose`
- Actual logic lives in `/scripts` which runs inside Docker containers
- Fast publishing uses a Docker volume (`fast_deploy_cache`) for persistence

## Available Scripts

### `./bin/publish`
Generates and publishes the blog to GitHub Pages (master branch). This script:
1. Checks for uncommitted and unpushed changes (unless --force is used)
2. Runs Jekyll build inside Docker
3. Creates a temporary directory
4. Initializes a new git repository
5. Force pushes to the master branch

**Usage:** 
```bash
./bin/publish           # Normal publish (checks for clean repository)
./bin/publish --force   # Force publish (skips repository checks)
```

### `./bin/publish_fast`
Publishes using a cached clone stored in a Docker volume for faster deployment. This script:
1. Checks for uncommitted and unpushed changes (unless --force is used)
2. Runs Jekyll build inside Docker
3. Uses rsync to sync files to the cached directory
4. Commits and pushes changes

**Usage:** 
```bash
./bin/publish_fast           # Normal fast publish (checks for clean repository)
./bin/publish_fast --force   # Force fast publish (skips repository checks)
```

**Note:** You must run `./bin/setup_fast_publish` first to set up the cached repository.

### `./bin/setup_fast_publish`
Sets up the cached repository in a Docker volume for fast publishing. This only needs to be run once.

**Usage:** `./bin/setup_fast_publish`

The cached repository is stored in the `fast_deploy_cache` Docker volume, which persists between container runs.

### `./bin/dev`
Starts the Jekyll development server using Docker Compose.

**Usage:** `./bin/dev`

### `./bin/social`
Creates Buffer social media posts for a blog post. Requires Buffer API access token and profile IDs.

**Usage:** `./bin/social _posts/YYYY-MM-DD-post-title.md`

**Required Environment Variables:**
- `BUFFER_ACCESS_TOKEN`: Your Buffer API access token
- `BUFFER_TWITTER_PROFILE_ID`: Twitter profile ID (optional)
- `BUFFER_LINKEDIN_PROFILE_ID`: LinkedIn profile ID (optional)
- `BUFFER_BLUESKY_PROFILE_ID`: Bluesky profile ID (optional)

## Docker Volume Management

The fast publishing cache is stored in a Docker volume. You can manage it with:

```bash
# View the volume
docker volume ls | grep fast_deploy_cache

# Inspect the volume
docker volume inspect talkingquicklygithubio_fast_deploy_cache

# Remove the volume (if you need to reset)
docker volume rm talkingquicklygithubio_fast_deploy_cache
```

## Safety Checks

The publish scripts include safety checks to prevent the source branch and published site from getting out of sync:

- **Uncommitted changes check**: Prevents publishing if you have local changes that aren't committed
- **Unpushed commits check**: Prevents publishing if your local branch has commits not pushed to the remote
- **Force flag**: Use `--force` to override these checks when necessary

This ensures that what's published always matches what's in your source repository.

## Requirements

- Docker and Docker Compose installed
- Git SSH keys must be available
- SSH agent running with your GitHub key loaded

## SSH Agent Setup

The scripts automatically forward your SSH agent to the Docker container. Before running publish scripts:

### Linux/macOS Setup
```bash
# Start SSH agent if not running
eval $(ssh-agent)

# Add your GitHub SSH key
ssh-add ~/.ssh/id_ed25519  # or your key name

# Verify key is loaded
ssh-add -l

# Now run the scripts
./bin/publish
```

### Persistent SSH Agent (recommended)
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# Auto-start SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent)
    ssh-add ~/.ssh/id_ed25519
fi
```

## Troubleshooting

### SSH Key Issues
If you see "Permission denied (publickey)" errors:

1. **Check SSH agent is running:**
   ```bash
   echo $SSH_AUTH_SOCK  # Should show a socket path
   ssh-add -l           # Should list your keys
   ```

2. **Add your GitHub key:**
   ```bash
   ssh-add ~/.ssh/your_github_key
   ```

3. **Test GitHub connection:**
   ```bash
   ssh -T git@github.com  # Should show "Hi username!"
   ```

4. **Debug inside container:**
   ```bash
   docker compose run --rm shell bash
   # Inside container:
   ssh -T git@github.com
   ```

### Fast Deploy Issues
If fast deploy isn't working or you get "Device or resource busy" errors:

**Option 1: Reset the existing repository (recommended)**
```bash
./bin/setup_fast_publish
# Choose 'y' when prompted to reset
```

**Option 2: Remove the Docker volume completely**
```bash
# Stop any running containers first
docker compose down

# Remove the volume
docker volume rm talkingquicklygithubio_fast_deploy_cache

# Run setup again
./bin/setup_fast_publish
```

**Note:** The deploy directory is stored in a Docker volume, so you cannot remove it with `rm -rf` while it's mounted. The setup script now handles this by resetting the git repository instead of trying to delete the directory.

### Permission Issues
All scripts run as the `deploy` user inside Docker, which should match the ownership of mounted files.