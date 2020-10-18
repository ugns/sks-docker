# SKS OpenPGP Keyserver

## Intro

This is a containerized [SKS OpenPGP Keyserver](https://github.com/SKS-Keyserver/sks-keyserver) using [s6-overlay](https://github.com/just-containers/s6-overlay) on an [Alpine Linux](http://alpinelinux.org) base image.

## Guide

The `/var/lib/sks` volume holds the key database, membership and sksconf files which should be mounted from a persistent storage source.

The container provides 4 long-running services under s6 supervision:

- `sks-db` - primary dependent service that terminates the container if it crashes
- `sks-recon` - SKS gossip peering process which only starts after `sks-db`
- `sks-stats` - generate DB statistics once an half hour by sending `sks-db` a USR2 signal
- `sks-log-clean` - execute db_archive against key and PTree databases 2 hours

### Setup

Initialize the key database from a keydump

```shell
docker service create --name sks --replicas X \
  --mount type=volume,src=sks-data,dst=/var/lib/sks,volume-driver=local \
  --mount type=bind,src=/path/to/keydump,dst=/var/lib/sks/dump,readonly \
  --restart-condition none jtbouse/sks:latest sks-init
```

Create an overlay network to utilize Docker swarm mesh routing

```shell
docker network create --driver overlay --subnet 10.0.9.0/24 my-network
```

### Run

Create the swarm service

```shell
docker service create --name sks --replicas X \
  --network my-network --publish 11370:11370 \
  --mount type=volume,src=sks-data,dst=/var/lib/sks,volume-driver=local \
  jtbouse/sks:latest
```

The container does not contain a web page front end so you either need to include it under the `/var/lib/sks/web` on the volume and expose port 11371/tcp, or preferaby as a separate container running Apache or Nginx which exposes port 11371/tcp and reverse proxies to the container by Docker swarm mesh routing to "http://tasks.sks:11731" to target the replica containers individually or "http://sks:11371" to target the VIP.
