FROM debian:latest
LABEL maintainer="Jeremy T. Bouse <Jeremy.Bouse@UnderGrid.net>"

ENV KEYDUMP_URL="https://mirror.cyberbits.eu/sks/dump/"

RUN set -ex \
    && apt-get update && apt-get install -y \
        jq \
        curl \
        wget \
        rsync \
    && mkdir -p /var/lib/sks/dump \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

WORKDIR /var/lib/sks
ENTRYPOINT [ "/entrypoint.sh" ]