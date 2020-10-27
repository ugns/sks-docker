#!/bin/bash

# Start daemons
if [ $# -gt 0 ];then
  exec "$@"
else
  (cd /var/lib/sks/dump && 
    wget --quiet --recursive --no-parent --no-directories \
        --accept pgp --execute robots=off --no-check-certificate ${KEYDUMP_URL})
fi