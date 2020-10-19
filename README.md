# SKS OpenPGP Keyserver

## Intro

This is a containerized [SKS OpenPGP Keyserver][1] using [s6-overlay][2] on an
[Alpine Linux][3] base image.

Including improvements based on [Óscar García Amor][4] and [Martin Dobrev][5]
derived forks of this repository.

## Guide

The `/var/lib/sks` volume holds the key database, membership and sksconf files
which should be mounted from a persistent storage source.

The container provides 4 long-running services under s6 supervision:

- `sks-db` - primary dependent service that terminates the container if it crashes
- `sks-recon` - SKS gossip peering process which only starts after `sks-db`
- `sks-stats` - generate DB statistics once an half hour by sending `sks-db` a USR2 signal
- `sks-log-clean` - execute db_archive against key and PTree databases 2 hours

## Setup

### Configuration

The `entrypoint.sh` script will make use of the following environment variables
to setup the default `sksconf` config file and modify on restarts unless altered
manually to no longer make use of the environment variables.

| Variable              | Default value |
| --------------------- | ------------- |
| SKS_HOSTNAME          | localhost     |
| SKS_RECON_ADDR        | 0.0.0.0       |
| SKS_RECON_PORT        | 11370         |
| SKS_HKP_ADRESS        | 0.0.0.0       |
| SKS_HKP_PORT          | 11371         |
| SKS_SERVER_CONTACT    |               |
| SKS_NODENAME          | keys          |
| SKS_COMMAND_TIMEOUT   | 600           |
| SKS_WSERVER_TIMEOUT   | 30            |
| SKS_MAX_RECOVER       | 150           |
| SKS_INIT_BUILD_FILES  | 10            |
| SKS_INIT_BUILD_CACHE  | 100           |
| SKS_INIT_PBUILD_CACHE | 20            |
| SKS_INIT_PTREE_CACHE  | 70            |

While other configuration options are available they are not managed at this
time and would require editing the `sksconf` file directly.

### Storage

The default persistent storage volume needed should be mounted to
`/var/lib/sks` and will store the key (KDB) and ptree (PTree) databases along
with the `sksconf`, `membership` and `DB_CONFIG` files.

If a keydump volume is mounted to `/data/dump` to the container and the key and
ptree databases do not yet exist, the `entrypoint.sh` will begin the database
build process automatically. The choice of path was made to ensure it was outside
the normal SKS basedir path so as not to be opened upon restart if the database
already exists and the mount has not been removed. Once the keydump has been imported
this mount volume could be removed as it is only necessary for initial import.

### Keydump

To be of much use the SKS keyserver requires an initial dump of the available
keys to be imported. As the version of `wget` available within [Alpine Linux][2]
does not fully support the necessary options to mirror a keydump source, an
additional [Debian][6] base image has been made available in the `keydump`
directory of this repostory.

This may be built using the following:

```shell
docker build -t sks-keydump -f keydump/Dockerfile keydump/
```

This image takes an optional environment variable of `KEYDUMP_URL` which
defaults to [cyberbits.eu][7] but can be pointed to any web accessible URL to
retrieve from.

Use of this is completely optional but can make retrieving an initial keydump
relatively simple to populate a volume that can then be mounted to the SKS container
for import.

### Run

[1]: https://github.com/SKS-Keyserver/sks-keyserver
[2]: http://alpinelinux.org
[3]: https://github.com/just-containers/s6-overlay
[4]: https://github.com/ogarcia/docker-sks
[5]: https://github.com/mclueppers/docker-sks
[6]: https://www.debian.org/
[7]: https://mirror.cyberbits.eu/sks/dump/
