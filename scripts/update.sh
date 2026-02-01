#!/bin/bash
set -e

# Day-2 update script: pulls latest changes, copies rendered files, and restarts services
# Repository is kept separate at /opt/infra (git repo)
# Services run from /opt/app (working directory)

GIT_REPO_DIR="/opt/infra"
APP_DIR="/opt/app"
ENVIRONMENT="${1:-staging}"

if [[ ! -d "$GIT_REPO_DIR" ]]; then
    echo "Error: Git repository not found at $GIT_REPO_DIR"
    exit 1
fi

if [[ ! -d "$APP_DIR" ]]; then
    echo "Error: App directory not found at $APP_DIR"
    exit 1
fi

echo "Updating from git repository..."
cd "$GIT_REPO_DIR"
git pull

echo "Copying rendered files for environment: $ENVIRONMENT"
# Copy all rendered files to app directory
cp "$GIT_REPO_DIR/rendered/$ENVIRONMENT"/* "$APP_DIR/"
cp -r "$GIT_REPO_DIR/rendered/$ENVIRONMENT/nginx" "$APP_DIR/"

echo "Restarting docker-compose services..."
cd "$APP_DIR"
docker-compose pull
docker-compose up -d

echo "Update complete"
