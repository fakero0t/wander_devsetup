FROM postgres:14-alpine

# Copy seed script to initialization directory
COPY init/seed.sql /docker-entrypoint-initdb.d/seed.sql

# Environment variables will be passed at runtime
ENV POSTGRES_DB=wander_dev
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=dev_password

EXPOSE 5432

# Healthcheck
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD pg_isready -U postgres -d wander_dev || exit 1

