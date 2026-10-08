#!/bin/sh
set -e

chown -R fiab:fiab /data/

# Fix ownership of the earthkit-data cache directory, which may be a freshly
# mounted volume owned by root (e.g. a named docker-compose volume).
if [ -d /data_cache/ ]; then
    chown -R fiab:fiab /data_cache/
fi

exec gosu fiab "$@"
