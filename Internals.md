# Project Internals & Developer Guide

This document explains the internal workings of the Drupal Docker environment. It is intended for developers who may need to maintain, extend, or debug the project. We assume you have basic command-line knowledge but may be new to Docker.

## Core Concept: What is Docker?

Think of Docker as a way to package an application and all its dependencies (like PHP, a database, a web server) into a standardized, isolated box called a **container**. This container can run on any machine that has Docker installed, guaranteeing that it will work the same way everywhere.

*   **Image:** A read-only blueprint for a container. It's like a class in object-oriented programming. Our `Dockerfile.drupal` creates a custom blueprint for our Drupal container.
*   **Container:** A live, running instance of an image. It's like an object or an instance of a class.
*   **Docker Compose:** A tool for defining and running applications that use multiple containers. Our `docker-compose.yml` file is the master plan that tells Docker Compose how to build and connect our Drupal, MariaDB, and Nginx containers.

---

## File-by-File Breakdown

Here is a description of each important file in this project.

### `manage_drupal.sh`

*   **Purpose:** A simple, friendly script to hide the complexity of Docker Compose commands.
*   **How it Works:** This is a standard Bash script that uses a `case` statement to translate simple arguments like `--init` into the corresponding `docker compose` commands (e.g., `docker compose up -d --build`).
*   **How to Extend:** To add a new command, simply add a new option to the `case` statement. For example, to add a command that shows the container logs, you could add:
    ```bash
    --logs)
        docker compose logs -f
        ;;
    ```

### `docker-compose.yml`

*   **Purpose:** The central configuration file for our multi-container application.
*   **How it Works:** This YAML file defines three main **services**:
    1.  `mariadb`: Runs the database using a standard MariaDB image.
    2.  `drupal`: Runs the Drupal application using a custom image built from our `Dockerfile.drupal`.
    3.  `nginx`: Runs the web server using a custom image from our `Dockerfile.nginx`.
    It also defines the **volumes** (for persistent data storage) and the **networks** (for container communication).
*   **Key Concept - `depends_on`:** This ensures containers start in the correct order. For example, the `drupal` container will wait for the `mariadb` container to be healthy before it starts.

### `.env`

*   **Purpose:** To store environment-specific variables, like passwords and ports.
*   **How it Works:** The `docker-compose.yml` file automatically reads this file and substitutes the variables (e.g., `${MARIADB_PASSWORD}`) with the values found here. This is a security best practice that keeps sensitive information out of your main configuration files.

#### Environment Variables

| Variable | Default Value | Service | Description |
| :--- | :--- | :--- | :--- |
| `MARIADB_ROOT_PASSWORD` | `supersecretrootpassword` | `mariadb` | The root password for the MariaDB database. Used for initial setup. |
| `MARIADB_DATABASE` | `drupal` | `mariadb`, `drupal` | The name of the database that Drupal will use. |
| `MARIADB_USER` | `drupal` | `mariadb`, `drupal` | The username that Drupal will use to connect to the database. |
| `MARIADB_PASSWORD` | `drupal` | `mariadb`, `drupal` | The password for the Drupal database user. |
| `HOST_PORT` | `8080` | `nginx` | The port on your local machine that will be forwarded to the Nginx container's port 80. |

### `Dockerfile.drupal`

*   **Purpose:** To create a custom blueprint for our main Drupal application container.
*   **How it Works:**
    1.  `FROM drupal:11.2.3-php8.3-fpm`: It starts with the official Drupal image.
    2.  `RUN apt-get update && apt-get install ...`: It runs commands *inside the image during the build process* to install helpful debugging tools like `vim` and `ps`.
    3.  `COPY ...`: It copies our custom settings files into the image.
    4.  `ENTRYPOINT`: This is a crucial step. It sets a custom script (`custom-entrypoint.sh`) to run every time a container is started from this image.
*   **How to Extend:** If you need a new PHP extension (e.g., `redis`), you would add the necessary `RUN` commands here to install it.

### `drupal_settings/` Directory

This directory contains files that are copied into our custom Drupal image to configure it at runtime.

*   **`settings.php`:** A custom Drupal settings file. It's designed to be dynamic, pulling database credentials from environment variables (`getenv(...)`). This is what allows our `docker-compose.yml` to securely pass the password from the `.env` file to Drupal.
*   **`entrypoint.sh`:** This script ensures our custom `settings.php` is always in the right place when the container starts. This is a robust pattern that makes the setup very reliable.

### `nginx.conf` & `Dockerfile.nginx`

*   **Purpose:** To configure and build our web server.
*   **How it Works:** The `nginx.conf` file defines how Nginx should handle incoming web requests. It knows how to serve static files (CSS, images) and how to forward any request for a PHP file to our `drupal` container (`fastcgi_pass drupal:9000;`). The `Dockerfile.nginx` simply takes the base Nginx image and adds debugging tools.
*   **How to Extend:** If you needed to add a custom Nginx rule, like a redirect or a security header, you would edit the `nginx.conf` file.

---

## Data Persistence and State

A key design principle of this environment is that it is **stateful**. Your work is not lost when you stop the containers. This is achieved through **Docker Named Volumes**.

In the `docker-compose.yml` file, you will see volume definitions:

```yaml
volumes:
  drupal_db_data:
  drupal_code:
```

And these are mapped into the services:

*   `drupal_db_data:/var/lib/mysql`: The MariaDB container's internal data directory is mapped to a persistent volume on the host machine named `drupal_db_data`.
*   `drupal_code:/var/www/html`: The Drupal application's code directory is mapped to a persistent volume on the host named `drupal_code`.

This means that when you run a command like `composer require` inside the `drupal-app` container, or when you create a new article in the Drupal UI, you are writing data directly to these managed volumes on your computer's hard drive.

The containers can be thought of as ephemeral (temporary), while the volumes are the permanent storage. The `--destroy` command is the only operation that will remove these volumes and reset the project.

---

## How the Containers Work Together

1.  A user sends a request to `http://localhost:8080`.
2.  Docker forwards this request to the **Nginx container**.
3.  Nginx looks at the request. If it's for a PHP page, it passes the request to the **Drupal container** on its internal network address (`drupal:9000`).
4.  The **Drupal container** (running PHP-FPM) executes the Drupal code.
5.  If the Drupal code needs to talk to the database, it connects to the **MariaDB container** using the internal network address `mariadb`.
6.  The response travels back through the same chain to the user's browser.

### The Private Network

By default, Docker Compose creates a private virtual network for the application. All containers defined in the `docker-compose.yml` file are attached to this network.

This is what allows the containers to communicate with each other using their service names as hostnames. For example, when the Nginx container passes a request to `drupal:9000`, Docker's internal DNS resolves `drupal` to the private IP address of the `drupal-app` container on this network.

This provides a significant security benefit: the database and application containers do not need to expose any ports to the host machine or the outside world. The only public entry point is the Nginx container on port 8080.
