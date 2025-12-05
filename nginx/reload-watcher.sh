#!/bin/sh
# Nginx Certificate Reload Watcher
# Watches for certificate updates and reloads nginx automatically

CERT_PATH="/etc/letsencrypt/live/home.dl-dev.de/fullchain.pem"
RELOAD_FLAG="/etc/letsencrypt/reload-required"
LAST_MODIFIED=0
CHECK_INTERVAL=60  # Check every minute

echo "[Nginx Watcher] Starting certificate reload watcher..."
echo "[Nginx Watcher] Monitoring: $CERT_PATH"
echo "[Nginx Watcher] Reload flag: $RELOAD_FLAG"
echo "[Nginx Watcher] Check interval: ${CHECK_INTERVAL}s"

reload_nginx() {
    echo "[Nginx Watcher] Testing nginx configuration..."
    if nginx -t 2>&1; then
        echo "[Nginx Watcher] Configuration valid, reloading nginx..."
        if nginx -s reload 2>&1; then
            echo "[Nginx Watcher] ✓ Nginx reloaded successfully at $(date)"
            return 0
        else
            echo "[Nginx Watcher] ✗ ERROR: nginx reload failed!"
            return 1
        fi
    else
        echo "[Nginx Watcher] ✗ ERROR: nginx configuration test failed!"
        return 1
    fi
}

while true; do
    # Check for reload flag first (instant response to certbot renewal)
    if [ -f "$RELOAD_FLAG" ]; then
        echo "[Nginx Watcher] Reload flag detected! Certificate was renewed."
        if reload_nginx; then
            # Remove flag after successful reload
            rm -f "$RELOAD_FLAG"
            echo "[Nginx Watcher] Reload flag removed"
        fi
    fi

    # Also check certificate modification time (fallback method)
    if [ -f "$CERT_PATH" ]; then
        CURRENT_MODIFIED=$(stat -c %Y "$CERT_PATH" 2>/dev/null || stat -f %m "$CERT_PATH" 2>/dev/null || echo "0")

        if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ] && [ "$LAST_MODIFIED" != "0" ]; then
            echo "[Nginx Watcher] Certificate modification detected!"
            echo "[Nginx Watcher] Old mtime: $LAST_MODIFIED, New mtime: $CURRENT_MODIFIED"
            reload_nginx
        fi

        LAST_MODIFIED=$CURRENT_MODIFIED
    else
        echo "[Nginx Watcher] WARNING: Certificate file not found: $CERT_PATH"
    fi

    sleep $CHECK_INTERVAL
done
