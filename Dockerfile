FROM tensorchord/vchord-postgres:pg18-v1.1.1

# Set DEBIAN_FRONTEND to noninteractive to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV POSTGRES_SHARED_PRELOAD_LIBRARIES="pg_jieba.so,vectors.so,age.so,pg_cron,pg_stat_statements,pg_partman_bgw,pgaudit"

# Arguments
ARG PG_MAJOR=18

# 1. Switch main Debian/Ubuntu APT sources to a Chinese mirror (Aliyun)
#    and PGDG sources to Tsinghua mirror for potentially faster downloads.
RUN \
  echo "INFO: Attempting to switch main Debian APT sources to mirrors.aliyun.com..." && \
  if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
    echo "INFO: Modifying /etc/apt/sources.list.d/debian.sources" && \
    sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources; \
  elif [ -f /etc/apt/sources.list ]; then \
    echo "INFO: Modifying /etc/apt/sources.list" && \
    sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list; \
  else \
    echo "WARNING: Standard Debian/Ubuntu APT source files not found in expected locations."; \
  fi && \
  echo "INFO: Attempting to switch PGDG APT source to mirrors.tuna.tsinghua.edu.cn..." && \
  find /etc/apt/sources.list* -type f -name '*.list' -exec \
    sed -i 's|http://apt.postgresql.org/pub/repos/apt|http://mirrors.tuna.tsinghua.edu.cn/postgresql/repos/apt|g' {} + || \
  echo "WARNING: PGDG APT source replacement did not find a typical pgdg.list or encountered an error. Proceeding..."

# 2. Add the PGroonga package source and install packaged extensions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    lsb-release \
    wget \
    postgresql-contrib-${PG_MAJOR} \
    postgresql-${PG_MAJOR}-cron \
    postgresql-${PG_MAJOR}-partman \
    postgresql-${PG_MAJOR}-postgis-3 \
    postgresql-${PG_MAJOR}-pgaudit \
    postgresql-${PG_MAJOR}-repack \
    build-essential \
    unzip \
    procps \
    cmake \
    postgresql-server-dev-${PG_MAJOR} && \
    wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
    apt-get install -y --no-install-recommends \
      ./groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
    rm -f ./groonga-apt-source-latest-$(lsb_release --codename --short).deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-${PG_MAJOR}-pgdg-pgroonga && \
    rm -rf /var/lib/apt/lists/*

# 3. Copy pg_jieba from local source
COPY pg_jieba/ /tmp/pg_jieba

# 4. Fix directory structure for limonp
RUN mkdir -p /tmp/pg_jieba/libjieba/deps && \
    # Move limonp to deps directory if it exists in the wrong location
    if [ -d "/tmp/pg_jieba/libjieba/limonp" ]; then \
      mv /tmp/pg_jieba/libjieba/limonp /tmp/pg_jieba/libjieba/deps/; \
    fi && \
    # Ensure include directories are available to compiler
    ln -sf /tmp/pg_jieba/libjieba/deps/limonp/include/limonp /usr/include/limonp

# 5. Create build directory and compile pg_jieba
RUN cd /tmp/pg_jieba && mkdir -p build && cd build && \
    cmake -DPostgreSQL_LIBRARY=/usr/lib/postgresql/${PG_MAJOR}/bin \
          -DPostgreSQL_INCLUDE_DIR=/usr/include/postgresql/${PG_MAJOR} \
          -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql/${PG_MAJOR}/server \
          .. && \
    make && make install

# 6. Clean up pg_jieba sources
RUN rm -rf /tmp/pg_jieba

# 7. Install dependencies for Apache AGE
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    unzip \
    libreadline-dev \
    zlib1g-dev \
    flex \
    bison \
    libxml2-dev \
    libxslt1-dev \
    libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# 8. install Apache AGE
COPY age/ /tmp/age

RUN cd /tmp/age && \
    make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config && \
    make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config install && \
    rm -rf /tmp/age && \
    echo "INFO: Apache AGE installed successfully"

# 9. Install dependencies for pgvector
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#    git \
#    libipc-run-perl && \
#    rm -rf /var/lib/apt/lists/*

# 10. install pgvector \
#COPY pgvector/ /tmp/pgvector
#
#RUN cd /tmp/pgvector && \
#    make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config && \
#    make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config install && \
#    rm -rf /tmp/pgvector && \
#    echo "INFO: pgvector installed successfully"

# 11. Modify PostgreSQL configuration to load extensions
RUN printf "shared_preload_libraries = '%s'\ncompute_query_id = on\n" "$POSTGRES_SHARED_PRELOAD_LIBRARIES" >> /usr/share/postgresql/${PG_MAJOR}/postgresql.conf.sample

# 12. Clean up build dependencies
RUN apt-get update && \
    apt-get purge -y build-essential unzip cmake wget lsb-release && \
    apt-get purge -y postgresql-server-dev-${PG_MAJOR} && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*
