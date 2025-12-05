#!/bin/sh
# Nginx Entrypoint with Certificate Reload Watcher

set -e

echo "Starting nginx with certificate reload watcher..."

# Start the certificate reload watcher in the background
/usr/local/bin/reload-watcher.sh &
WATCHER_PID=$!
echo "Certificate watcher started with PID: $WATCHER_PID"

# Start nginx in the foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"
