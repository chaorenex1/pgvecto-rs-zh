ARG UBUNTU_VERSION=24.04
ARG PG_MAJOR=18
ARG PG_VERSION=18.3

FROM ubuntu:${UBUNTU_VERSION} AS pg-builder
ARG DEBIAN_FRONTEND=noninteractive
ARG PG_MAJOR
ARG PG_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN packages=(
      bison
      build-essential
      ca-certificates
      curl
      flex
      libedit-dev
      libicu-dev
      liblz4-dev
      libreadline-dev
      libssl-dev
      liburing-dev
      libxml2-dev
      libxslt1-dev
      libzstd-dev
      locales
      pkg-config
      wget
      xz-utils
      zlib1g-dev
    ) \
    && apt-get update \
    && apt-get install -y --no-install-recommends "${packages[@]}" \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY docker/versions.env docker/versions.env
COPY docker/build-scripts/build-postgresql.sh docker/build-scripts/build-postgresql.sh
COPY docker/build-scripts/common.sh docker/build-scripts/common.sh
COPY sources/ sources/
RUN chmod +x docker/build-scripts/build-postgresql.sh docker/build-scripts/common.sh \
    && set -a \
    && . docker/versions.env \
    && set +a \
    && docker/build-scripts/build-postgresql.sh /workspace/sources

FROM ubuntu:${UBUNTU_VERSION} AS ext-builder
ARG DEBIAN_FRONTEND=noninteractive
ARG PG_MAJOR
ARG PG_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/root/.cargo/bin:/usr/local/pgsql/bin:$PATH \
    PG_CONFIG=/usr/local/pgsql/bin/pg_config

RUN packages=(
      bison
      build-essential
      ca-certificates
      clang
      cmake
      curl
      flex
      git
      groonga-token-filter-stem
      groonga-tokenizer-mecab
      libclang-dev
      libedit-dev
      libgdal-dev
      libgeos-dev
      libgroonga-dev
      libicu-dev
      libjson-c-dev
      liblz4-dev
      libmsgpack-dev
      libproj-dev
      libprotobuf-c-dev
      libreadline-dev
      libsfcgal-dev
      libssl-dev
      liburing-dev
      libxml2-dev
      libxslt1-dev
      libxxhash-dev
      libzstd-dev
      locales
      meson
      ninja-build
      pkg-config
      procps
      ruby
      unzip
      wget
      zlib1g-dev
    ) \
    && apt-get update \
    && apt-get install -y --no-install-recommends "${packages[@]}" \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --location --silent --show-error https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain stable

COPY --from=pg-builder /usr/local/pgsql /usr/local/pgsql
WORKDIR /workspace
COPY docker/versions.env docker/versions.env
COPY docker/build-scripts/ docker/build-scripts/
COPY sources/ sources/
RUN chmod +x docker/build-scripts/*.sh \
    && set -a \
    && . docker/versions.env \
    && set +a \
    && docker/build-scripts/build-core-extensions.sh /workspace/sources \
    && docker/build-scripts/build-heavy-extensions.sh /workspace/sources \
    && docker/build-scripts/build-vector-stack.sh /workspace/sources

FROM ubuntu:${UBUNTU_VERSION} AS runtime
ARG DEBIAN_FRONTEND=noninteractive
ARG PG_MAJOR
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH=/usr/local/pgsql/bin:$PATH \
    PGDATA=/var/lib/postgresql/data \
    POSTGRES_USER=postgres \
    POSTGRES_DB=postgres

RUN packages=(
      ca-certificates
      gosu
      groonga-token-filter-stem
      groonga-tokenizer-mecab
      libedit-dev
      libgdal-dev
      libgeos-dev
      libgroonga-dev
      libicu-dev
      libjson-c-dev
      liblz4-dev
      libmsgpack-dev
      libproj-dev
      libprotobuf-c-dev
      libreadline-dev
      libsfcgal-dev
      libssl-dev
      liburing-dev
      libxml2-dev
      libxslt1-dev
      libxxhash-dev
      libzstd-dev
      locales
      procps
      ruby
      tini
      tzdata
      zlib1g-dev
    ) \
    && apt-get update \
    && apt-get install -y --no-install-recommends "${packages[@]}" \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ext-builder /usr/local/pgsql /usr/local/pgsql
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker/postgresql.conf /etc/postgresql/postgresql.conf
COPY docker/initdb/ /docker-entrypoint-initdb.d/
COPY docker/sysctl/99-postgres.conf /etc/sysctl.d/99-postgres.conf
COPY docker/security/limits.d/postgres.conf /etc/security/limits.d/postgres.conf

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && groupadd --system postgres \
    && useradd --system --gid postgres --home-dir /var/lib/postgresql --shell /bin/bash postgres \
    && mkdir -p /var/lib/postgresql/data /var/run/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql \
    && chmod 2775 /var/run/postgresql

VOLUME ["/var/lib/postgresql/data"]
EXPOSE 5432
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres"]
