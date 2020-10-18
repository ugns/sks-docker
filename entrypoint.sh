#!/bin/sh

fail() { echo Command failed unexpectedly. Bailing out; exit 1; }

#
# Make basic SKS config file
#
if ! test -f sksconf; then
cat > sksconf << EOF
hostname: ${SKS_HOSTNAME}
recon_address: ${SKS_RECON_ADDR}
recon_port: ${SKS_RECON_PORT}
hkp_address: ${SKS_HKP_ADRESS}
hkp_port: ${SKS_HKP_PORT}
initial_stat:
pagesize: 16
ptree_pagesize: 16
nodename: ${SKS_NODENAME}
disable_mailsync:
debuglevel: 3
membership_reload_interval: 1
stat_hour: 17
server_contact: ${SKS_SERVER_CONTACT}
command_timeout: 600
wserver_timeout: 30
max_recover: 150
EOF
else
sed -i "\
  s/hostname:.*/hostname: ${SKS_HOSTNAME}/g; \
  s/recon_address:.*/recon_address: ${SKS_RECON_ADDR}/g; \
  s/recon_port:.*/recon_port: ${SKS_RECON_PORT}/g; \
  s/hkp_address:.*/hkp_address: ${SKS_HKP_ADRESS}/g; \
  s/hkp_port:.*/hkp_port: ${SKS_HKP_PORT}/g; \
  s/nodename:.*/nodename: ${SKS_NODENAME}/g; \
  s/server_contact:.*/server_contact: ${SKS_SERVER_CONTACT}/g; \
  s/command_timeout:.*/command_timeout: ${SKS_COMMAND_TIMEOUT}/g; \
  s/wserver_timeout:.*/wserver_timeout: ${SKS_WSERVER_TIMEOUT}/g; \
  s/max_recover:.*/max_recover: ${SKS_MAX_RECOVER}/g; \
  " sksconf
fi

#
# Copy membership file
#
if ! test -f membership; then
  cp -a /usr/local/etc/sks/membership .
fi


#
# Copy BDB DB_CONFIG file
#
if ! test -f DB_CONFIG; then
  cp -a /usr/local/etc/sks/DB_CONFIG .
fi

#
# Handle key dump import if available and no KDB
#
if ! test -d KDB; then
  if [ -d /data/dump ] && [ "$(echo /data/dump/*.pgp)" != "/data/dump/*.pgp" ]; then
    ulimit -s unlimited
    echo "=== Running build... ==="
    if ! sks build /data/dump/*.pgp -n ${SKS_INIT_BUILD_FILES} -cache ${SKS_INIT_BUILD_CACHE} -stdoutlog; then rm -rf KDB; fail; fi
    echo "=== Cleaning key database... ==="
    if ! sks cleandb -stdoutlog; then fail; fi
    echo "=== Building ptree database... ==="
    if ! sks pbuild -cache ${SKS_INIT_PBUILD_CACHE} -ptree_cache ${SKS_INIT_PTREE_CACHE} -stdoutlog; then rm -rf PTree; fail; fi
    echo "=== Done! ==="
  fi
fi

# Start daemons
if [ $# -gt 0 ];then
  exec "$@"
else
  exec /init
fi