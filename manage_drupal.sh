#!/bin/bash
set -e

# ======================================================
# Author: Gemini 2.5 Pro - gemini-cli
# Human: J Dunphy - Aug 16, 2025
# ======================================================

# Ensure we are running from the script's directory
cd "$(dirname "$0")"

# --- Help Function ---
display_help() {
    echo "Usage: $0 {--init|--run|--stop|--shell-app|--shell-db|--shell-web|--destroy|--help}"
    echo ""
    echo "   --init         Initializes the environment and starts the stack."
    echo "   --run          Starts all Drupal services in the background."
    echo "   --stop         Stops all services and removes the containers."
    echo "   --shell-app    Opens a bash shell inside the Drupal application container."
    echo "   --shell-db     Opens a bash shell inside the MariaDB container."
    echo "   --shell-web    Opens a bash shell inside the Nginx web container."
    echo "   --destroy      Stops all services and PERMANENTLY DELETES ALL DATA."
    echo "   --package      Creates a tarball of the essential setup files for distribution."
    echo "   --clean-docker Remove all unused containers, images, networks, and volumes."
    echo "   --help         Displays this help message."
    echo ""
}

# --- Main Logic ---
case "$1" in
    --init)
        echo "Initializing Drupal environment..."
        # Create persistent data directories if they don't exist
        # Docker will create the named volumes automatically, but this is good practice
        # for potential future bind mounts.
        mkdir -p ./mnt/db
        mkdir -p ./mnt/code

        echo "Building and starting services..."
        docker compose up -d --build
        echo ""
        echo "Drupal is starting up. This may take a moment."
        echo "Once started, you can complete the installation in your browser."
        echo "Access it at: http://localhost:${HOST_PORT:-8080}"
        ;;
    --run)
        echo "Starting Drupal services..."
        docker compose up -d --build
        ;;
    --stop)
        echo "Stopping Drupal services..."
        docker compose down
        ;;
    --shell-app)
        echo "Opening shell into drupal-app container..."
        docker exec -it drupal-app /bin/bash
        ;;
    --shell-db)
        echo "Opening shell into drupal-db container..."
        docker exec -it drupal-db /bin/bash
        ;;
    --shell-web)
        echo "Opening shell into drupal-web container..."
        docker exec -it drupal-web /bin/bash
        ;;
    --destroy)
        echo "PERMANENTLY DESTROYING all containers and data volumes..."
        docker compose down --volumes
        echo "Cleanup complete."
        ;;
    --package)
        echo "Creating Drupal setup package..."
        PACKAGE_NAME="drupal_docker_setup_$(date +%Y%m%d%H%M%S).tar.gz"
        tar -czvf "../$PACKAGE_NAME" README.md Internals.md .gitignore .env docker-compose.yml Dockerfile.drupal Dockerfile.nginx manage_drupal.sh nginx.conf drupal_settings/
        echo "Package created: ../$PACKAGE_NAME"
        ;;
    --uninstall)
        echo "Starting complete Drupal uninstallation..."
        "$0" --destroy
        echo "Removing persistent data directory..."
        rm -rf ./mnt
        echo "Uninstallation complete. This directory is now empty."
        ;;
    --clean-docker)
	docker system prune -a -f --volumes
        ;;
    --help)
        display_help
        ;;
    *)
        echo "Error: Invalid argument."
        echo ""
        display_help
        exit 1
        ;;
esac

exit 0
