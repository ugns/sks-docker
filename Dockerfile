FROM alpine:edge
MAINTAINER Jeremy T. Bouse <Jeremy.Bouse@UnderGrid.net>

ENV S6_BEHAVIOR_IF_STAGE2_FAILS=2

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache db-utils libgcc && \
    apk add --no-cache --virtual .sks-builddeps \
        build-base camlp4 curl db-dev zlib-dev && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz | tar xvzf - -C /  && \
    curl -sSL https://bitbucket.org/skskeyserver/sks-keyserver/get/1.1.6.tar.gz | tar xz && \
    mv skskeyserver* sks-keyserver && \
    cd sks-keyserver && \
        sed 's/db-.*/db-5.3/' Makefile.local.unused > Makefile.local && \
        make dep && \
        make cryptokit-1.7/README.txt && \
        sed -i 's/uint32/uint32_t/g' cryptokit-1.7/src/stubs-md5.c && \
        make sks && \
        strip sks && \
        install -m755 sks /usr/sbin/sks && \
    cd .. && \
    apk --purge del .sks-builddeps && \
    rm -rf sks-keyserver && \
    mkdir -p /var/lib/sks

COPY sks /usr/local/
COPY s6 /etc/
 
VOLUME /var/lib/sks
EXPOSE 11371 11370

CMD ["/init"]