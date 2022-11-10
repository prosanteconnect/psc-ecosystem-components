#!/usr/bin/dumb-init /bin/sh
set -e

for v in $(env | grep ^NOMAD_META_ | cut -d= -f1); do
  if [ -n "$meta_vars" ]; then
    meta_vars="${meta_vars},${v}"
  else
    meta_vars="${v}"
  fi
done

sigil -f ./filebeat.yml.tmpl meta_vars=$meta_vars > ./filebeat.yml

exec "$@"
