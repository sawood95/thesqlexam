# Medicare PostgreSQL Environment

This Compose stack loads `Medicare Public Data.sql` into PostgreSQL and makes
the database available through pgAdmin.

## Prerequisites

- Docker Engine or Docker Desktop
- Docker Compose v2 (`docker compose`)

## Run the Containers

From this repository's root directory:

```bash
cp .env.example .env
docker compose up -d
```

The first startup may take a few minutes while Docker downloads the images and
PostgreSQL imports the seed data. Check container status with:

```bash
docker compose ps
```

Both `postgres` and `pgadmin` should show as running, and PostgreSQL should show
as healthy. To follow startup logs:

```bash
docker compose logs -f
```

## Connect with pgAdmin

Open <http://localhost:5050> and sign in with:

| Setting | Default |
| --- | --- |
| Email | `admin@example.com` |
| Password | `admin` |

The `Medicare PostgreSQL` server is registered automatically. When pgAdmin
asks for the database password, enter `medicare`.

## Connect Directly to PostgreSQL

PostgreSQL is also available directly at `localhost:5432` with database and
user `medicare`:

| Setting | Default |
| --- | --- |
| Host | `localhost` |
| Port | `5432` |
| Database | `medicare` |
| Username | `medicare` |
| Password | `medicare` |

For example, using `psql` installed on the host:

```bash
PGPASSWORD=medicare psql -h localhost -U medicare -d medicare
```

The published PostgreSQL and pgAdmin ports are bound to localhost only. Default
credentials and ports can be changed in `.env` before starting the containers.

## Stop the Containers

Stop the services without deleting their data:

```bash
docker compose down
```

Start them again with `docker compose up -d`. PostgreSQL and pgAdmin data are
stored in Docker volumes and persist between runs.

## Seed data

Initialization scripts run only when the PostgreSQL volume is empty. To delete
all persisted database and pgAdmin data and rebuild from the seed files:

```bash
docker compose down --volumes
docker compose up -d
```

This reset permanently deletes changes made in the local database.
