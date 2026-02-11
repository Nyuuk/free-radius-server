FROM debian:bookworm-slim

ARG release=v3.0.x
ARG source=https://github.com/FreeRADIUS/freeradius-server.git

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install build deps + PostgreSQL Dev Headers
RUN apt-get update && apt-get install -y \
    git build-essential libssl-dev libtalloc-dev libpam0g-dev \
    libcap-dev libpcap-dev libcurl4-openssl-dev libjson-c-dev \
    libtool autoconf automake pkg-config ca-certificates \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone ${source} freeradius && \
    cd freeradius && \
    git checkout ${release}

WORKDIR /build/freeradius

# 2. Build dengan prefix yang konsisten
RUN ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --with-modules="rlm_sql_postgresql rlm_sqlcounter" \
    --disable-developer \
    && make -j$(nproc) \
    && make install

# 3. Perbaikan Path Symlink
# Setelah install, config berada di /etc/raddb/ (karena sysconfdir=/etc)
RUN ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql && \
    ln -s /etc/raddb/mods-available/sqlcounter /etc/raddb/mods-enabled/sqlcounter
# ln -s /etc/raddb/mods-available/ippool /etc/raddb/mods-enabled/ippool

# 4. Tambahkan dictionary mikrotik
RUN echo '$INCLUDE /usr/share/freeradius/dictionary.mikrotik' >> /etc/raddb/dictionary

EXPOSE 1812/udp 1813/udp

# Opsi 1: Mode Debug (-X) - Berguna untuk troubleshooting, menampilkan log sangat detail (auth, SQL queries, dll)
# CMD ["radiusd", "-f", "-X"]

# Opsi 2: Mode Standard Foreground (-f) dengan log ke stdout (-l stdout)
# Direkomendasikan untuk penggunaan normal agar log bisa dilihat via 'docker logs'
CMD ["radiusd", "-fl", "stdout"]