FROM postgres:16
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-$PG_MAJOR-pgvector \
