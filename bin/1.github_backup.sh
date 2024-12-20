#!/bin/bash

# Load configuration values from JSON
CONFIG_FILE="conf/app_config.json"

# Parse JSON for required values
GIT_USER=$(jq -r '.git_user' "$CONFIG_FILE")
GIT_TOKEN=$(jq -r '.git_token' "$CONFIG_FILE")
REMOTE_URL="https://${GIT_USER}:${GIT_TOKEN}@github.com/frobnitz.git"


# Backup directory
BACKUP_DIR="/home/fritz/Desktop/Acme-Frobnitz-Snapshot"

# Commit message
COMMIT_MSG="Backup on $(date +'%Y-%m-%d %H:%M:%S')"

# Navigate to the backup directory
cd "$BACKUP_DIR" || exit



# Switch to the backup branch
BRANCH="backup"
git checkout -B "$BRANCH"

# Stage changes
git add .

# Commit changes
git commit -m "$COMMIT_MSG"

# Push to the backup branch
git push -u origin "$BRANCH"

echo "Backup complete on branch '$BRANCH': $COMMIT_MSG"

