#!/bin/sh

### BEGIN INIT INFO
# Provides:          redis
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts redis database system
# Description:       starts redis using basic start scripts
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
NAME=redis

test -x $DAEMON || exit 0

set -e

case "$1" in
  start)
        echo -n "Starting $DESC: "

        start-stop-daemon --start --user redis -c redis:redis \
            --startas /usr/local/bin/redis-server -- /etc/redis/redis.conf

        echo "$NAME."
        ;;
  stop)
        echo -n "Stopping $DESC: "

        start-stop-daemon --stop --exec /usr/local/bin/redis-server -c redis:redis \
            /usr/local/bin/redis-server -- /etc/redis/redis.conf

        echo "$NAME."
        ;;
      *)    
            N=/etc/init.d/$NAME
            echo "Usage: $N {start|stop}" >&2
            exit 1
            ;;
    esac
    
    exit 0
