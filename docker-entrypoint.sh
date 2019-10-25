#!/bin/sh

export LD_LIBRARY_PATH=/usr/local/lib64

[ -f /var/run/minidlna/minidlna.pid ] && rm -f /var/run/minidlna/minidlna.pid

exec "$@"