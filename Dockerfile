FROM alpine:3.7 AS build

COPY patches /tmp/patches/

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        build-base camlp4 db-dev gcc libc-dev zlib-dev curl jq && \
    curl -sSL $(curl -s https://api.github.com/repos/SKS-Keyserver/sks-keyserver/releases/latest |jq -r '.assets[] | select(.content_type | contains("application/x-compressed-tar")) | .browser_download_url') | tar xzC /tmp && \
    cd /tmp/sks-* && \
    patch -p1 </tmp/patches/deprecated-ocaml.diff && \
    patch -p1 </tmp/patches/fix-build-failure.diff && \
    patch -p1 </tmp/patches/poison-key.diff && \
    sed 's/db-.*/db-5.3/' Makefile.local.unused > Makefile.local && \
    make dep && \
    make cryptokit-1.7/README.txt && \
    sed -i 's/uint32/uint32_t/g' cryptokit-1.7/src/stubs-md5.c && \
    make sks && \
    install -m755 sks /usr/sbin/sks 

FROM alpine:3
LABEL maintainer="Jeremy T. Bouse <Jeremy.Bouse@UnderGrid.net>"

ENV S6_BEHAVIOR_IF_STAGE2_FAILS=2 \
    SKS_HOSTNAME="localhost" \
    SKS_RECON_ADDR="0.0.0.0" \
    SKS_RECON_PORT="11370" \
    SKS_HKP_ADRESS="0.0.0.0" \
    SKS_HKP_PORT="11371" \
    SKS_SERVER_CONTACT="" \
    SKS_NODENAME="keys" \
    SKS_COMMAND_TIMEOUT="600" \
    SKS_WSERVER_TIMEOUT="30" \
    SKS_MAX_RECOVER="150" \
    SKS_INIT_BUILD_FILES="10" \
    SKS_INIT_BUILD_CACHE="100" \
    SKS_INIT_PBUILD_CACHE="20" \
    SKS_INIT_PTREE_CACHE="70"

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache db-utils && \
    apk add --no-cache --virtual .sks-setup \
        curl jq && \
    curl -sSL $(curl -s https://api.github.com/repos/just-containers/s6-overlay/releases/latest |jq -r '.assets[] | select(.browser_download_url | endswith("amd64.tar.gz")) | .browser_download_url') | tar xzC / && \
    apk del --purge .sks-setup && \
    mkdir -p /data && \
    mkdir -p /var/lib/sks

COPY --from=build /usr/sbin/sks /usr/sbin/
COPY sks /usr/local/
COPY s6 /etc/
COPY entrypoint.sh /

WORKDIR /var/lib/sks

VOLUME /var/lib/sks
EXPOSE 11371 11370

ENTRYPOINT ["/entrypoint.sh"]
