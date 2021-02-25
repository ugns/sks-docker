FROM alpine:3.7 AS build

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        build-base camlp4 db-dev gcc libc-dev zlib-dev git opam m4 gmp-dev perl
WORKDIR /tmp
RUN git clone https://github.com/SKS-Keyserver/sks-keyserver.git
COPY patches /tmp/patches/
WORKDIR /tmp/sks-keyserver
#RUN patch -p1 </tmp/patches/deprecated-ocaml.diff
#RUN patch -p1 </tmp/patches/fix-build-failure.diff
RUN patch -p1 </tmp/patches/poison-key.diff
RUN sed 's/db-.*/db-5.3/' Makefile.local.unused > Makefile.local
RUN opam init
ENV PATH="/root/.opam/system/bin:$PATH" \
    OCAML_TOPLEVEL_PATH="/root/.opam/system/lib/toplevel" \
    PERL5LIB="/root/.opam/system/lib/perl5:$PERL5LIB" \
    CAML_LD_LIBRARY_PATH="/root/.opam/system/lib/stublibs:/usr/lib/ocaml/stublibs"
RUN opam install ocamlfind
RUN opam install cryptokit
RUN make dep
RUN make all
RUN install -m755 sks /usr/sbin/sks 

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

COPY --from=build /usr/sbin/sks /usr/sbin/
COPY sks /usr/local/
COPY s6 /etc/
COPY entrypoint.sh /

RUN set -ex && \
    apk upgrade --no-cache && \
    apk add --no-cache db-utils gmp && \
    apk add --no-cache --virtual .sks-setup \
        curl jq && \
    curl -sSL $(curl -s https://api.github.com/repos/just-containers/s6-overlay/releases/latest |jq -r '.assets[] | select(.browser_download_url | endswith("amd64.tar.gz")) | .browser_download_url') | tar xzC / && \
    apk del --purge .sks-setup && \
    mkdir -p /data && \
    mkdir -p /var/lib/sks && \
    chmod +x /entrypoint.sh

WORKDIR /var/lib/sks

VOLUME /var/lib/sks
EXPOSE 11371 11370

ENTRYPOINT ["/entrypoint.sh"]
