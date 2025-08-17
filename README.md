# Drupal Docker Environment

This project provides a complete, containerized local development environment for a Drupal 11 site using Docker Compose.

## Prerequisites

- Docker
- Docker Compose

## Configuration

Before starting the environment for the first time, you will need to create a `.env` file. This file stores the configuration for your local environment, such as database credentials and ports.

Create a file named `.env` in the root of the project and copy the following content into it. You can change these values if you wish, but the defaults are configured to work out-of-the-box.

```env
# MariaDB Settings
# Note: Drupal will create the database if it doesn't exist.
MARIADB_ROOT_PASSWORD=supersecretrootpassword
MARIADB_DATABASE=drupal
MARIADB_USER=drupal
MARIADB_PASSWORD=drupal

# Nginx Settings
# This is the port on your host machine that will forward to the Nginx container.
HOST_PORT=8080
```

---

## Quick Start

This environment is managed by a single, easy-to-use shell script: `manage_drupal.sh`.

1.  **Initialize and Start the Environment:**
    This is the only command you need to run the first time. It will build the necessary Docker images and start all the services in the background.

    ```bash
    ./manage_drupal.sh --init
    ```

2.  **Access Your Site:**
    Once the services are running, you can access the Drupal site in your browser at [http://localhost:8080](http://localhost:8080) (or whichever port you have configured in the `.env` file).

3.  **Stop the Environment:**
    When you are finished working, you can stop all the running services.

    ```bash
    ./manage_drupal.sh --stop
    ```

## Typical Workflow (Start, Stop, Resume)

This environment is designed for a persistent development workflow. Your database and code changes are stored on your host machine and will not be lost when you stop the containers.

**1. Starting Your Workday:**

Use `--init` the very first time you start the project. For every subsequent start (e.g., after a reboot), use `--run`.

```bash
# On any day after the first, just run:
./manage_drupal.sh --run
```

**2. Making Changes:**

- Access the site at `http://localhost:8080`.
- Use `./manage_drupal.sh --shell-app` to run `composer` or `drush` commands. Any modules you add or code you change will be saved.
- Any content you create in the Drupal UI will be saved in the database.

**3. Stopping Your Workday ("Closing the Laptop"):**

When you are done, use `--stop` to shut down the containers and free up system resources.

```bash
./manage_drupal.sh --stop
```

All your work is safe. The next time you run `./manage_drupal.sh --run`, your site will be exactly as you left it.

---

## Script Usage and Commands

All management of the environment is done via the `manage_drupal.sh` script.

**Usage:** `./manage_drupal.sh {command}`

| Command | Description |
| :--- | :--- |
| `--init` | Builds the Docker images and starts all services for the first time. Also a great way to ensure a clean start if you've made changes to the Dockerfiles. |
| `--run` | Starts all services in the background. Use this to restart the environment after a `--stop`. |
| `--stop` | Stops all running containers related to the project. Your data is safe in Docker volumes. |
| `--destroy` | **PERMANENTLY** stops and removes all containers, networks, and data volumes. This is a destructive action and will delete your database. |
| `--shell-app` | Opens an interactive `bash` shell inside the main Drupal (PHP) container. Useful for running `composer` or `drush` commands. |
| `--shell-db` | Opens an interactive `bash` shell inside the MariaDB database container. Useful for database debugging. |
| `--shell-web` | Opens an interactive `bash` shell inside the Nginx web server container. |
| `--package` | Creates a `.tar.gz` archive of the core project configuration files for easy distribution. |
| `--clean-docker`| **CAUTION:** A utility to remove all unused Docker containers, images, networks, and volumes on your system to free up disk space. |
| `--help` | Displays the help message with all available commands. |

