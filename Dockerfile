FROM debian:buster-slim

ARG HYDRA_VER="9.2"

LABEL \
    org.opencontainers.image.url="https://github.com/tarampampam/hydra-docker" \
    org.opencontainers.image.source="https://github.com/tarampampam/hydra-docker" \
    org.opencontainers.image.version="$HYDRA_VER" \
    org.opencontainers.image.vendor="tarampampam" \
    org.opencontainers.image.title="hydra" \
    org.opencontainers.image.description="Docker image with hydra" \
    org.opencontainers.image.licenses="WTFPL"

RUN set -x \
    && apt-get update \
    && apt-get -y install \
        #libmysqlclient-dev \
        default-libmysqlclient-dev \
        libgpg-error-dev \
        #libmemcached-dev \
        #libgcrypt11-dev \
        libgcrypt-dev \
        #libgcrypt20-dev \
        #libgtk2.0-dev \
        libpcre3-dev \
        #firebird-dev \
        libidn11-dev \
        libssh-dev \
        #libsvn-dev \
        libssl-dev \
        #libpq-dev \
        make \
        curl \
        gcc \
        1>/dev/null \
    # The next line fixes the curl "SSL certificate problem: unable to get local issuer certificate" for linux/arm
    && c_rehash \
    # Get hydra sources and compile
    && mkdir /tmp/hydra \
        && curl -SsL "https://github.com.cnpmjs.org/vanhauser-thc/thc-hydra/archive/v${HYDRA_VER}.tar.gz" -o /tmp/hydra/src.tar.gz \
        && tar xzf /tmp/hydra/src.tar.gz -C /tmp/hydra \
        && cd "/tmp/hydra/thc-hydra-${HYDRA_VER}" \
        && ./configure 1>/dev/null \
        && make 1>/dev/null \
        && make install \
        && rm -Rf /tmp/hydra \
    # Make clean
    && apt-get purge -y make gcc libgpg-error-dev libgcrypt-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    # Verify hydra installation
    && hydra -h || error_code=$? \
    && if [ ! "${error_code}" -eq 255 ]; then echo "Wrong exit code for 'hydra help' command"; exit 1; fi \
    # Unprivileged user creation
    && adduser \
        --disabled-password \
        --gecos "" \
        --home /tmp \
        --shell /sbin/nologin \
        --no-create-home \
        --uid 10001 \
        hydra

ARG INCLUDE_SECLISTS="false"

RUN set -x \
    && if [ "${INCLUDE_SECLISTS}" = "true" ]; then \
        mkdir /tmp/seclists \
        && curl -SL "https://api.github.com.cnpmjs.org/repos/danielmiessler/SecLists/tarball" -o /tmp/seclists/src.tar.gz \
        && tar xzf /tmp/seclists/src.tar.gz -C /tmp/seclists \
        && mv /tmp/seclists/*SecLists*/Passwords /opt/passwords \
        && mv /tmp/seclists/*SecLists*/Usernames /opt/usernames \
        && chmod -R u+r /opt/passwords /opt/usernames \
        && rm -Rf /tmp/seclists \
        && ls -la /opt/passwords /opt/usernames \
    ;fi

# Use an unprivileged user
USER hydra:hydra

ENTRYPOINT ["/usr/local/bin/hydra"]