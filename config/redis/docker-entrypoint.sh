#!/bin/sh
set -e

escape_sed() {
  printf '%s\n' "$1" | sed 's/[&|\\]/\\&/g'
}

sed \
  -e "s|__ADMIN_PASSWORD__|$(escape_sed "$ADMIN_PASSWORD")|g" \
  -e "s|__APP_PASSWORD__|$(escape_sed "$APP_PASSWORD")|g" \
  -e "s|__SESSION_PASSWORD__|$(escape_sed "$SESSION_PASSWORD")|g" \
  -e "s|__QUEUE_PASSWORD__|$(escape_sed "$QUEUE_PASSWORD")|g" \
  /usr/local/etc/redis/acl.conf.template > /tmp/acl.conf

chmod 600 /tmp/acl.conf

exec /entrypoint.sh "$@"
