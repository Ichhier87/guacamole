#!/bin/sh
# Certbot Renewal Hook Script
# This script runs after successful certificate renewal

set -e

echo "[Certbot Hook] Certificate renewal detected at $(date)"

# Fix permissions on renewed certificates
echo "[Certbot Hook] Setting correct permissions on certificates..."
chmod -R 755 /etc/letsencrypt
find /etc/letsencrypt -type f -exec chmod 644 {} \;

# Check if certificates were actually renewed
if [ -f "/etc/letsencrypt/live/home.dl-dev.de/fullchain.pem" ]; then
    echo "[Certbot Hook] Certificate found, checking modification time..."

    # Get certificate modification time
    CERT_TIME=$(stat -c %Y /etc/letsencrypt/live/home.dl-dev.de/fullchain.pem 2>/dev/null || stat -f %m /etc/letsencrypt/live/home.dl-dev.de/fullchain.pem 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - CERT_TIME))

    # If certificate was modified in the last hour (3600 seconds), reload nginx
    if [ "$TIME_DIFF" -lt 3600 ]; then
        echo "[Certbot Hook] Certificate was renewed recently (${TIME_DIFF}s ago)"
        echo "[Certbot Hook] Reloading nginx..."

        # Try to reload nginx via docker exec
        if command -v docker >/dev/null 2>&1; then
            docker exec nginx nginx -t && docker exec nginx nginx -s reload
            echo "[Certbot Hook] nginx reloaded successfully!"
        else
            echo "[Certbot Hook] ERROR: Docker command not found"
            exit 1
        fi
    else
        echo "[Certbot Hook] Certificate not recently modified (${TIME_DIFF}s ago), skipping reload"
    fi
else
    echo "[Certbot Hook] WARNING: Certificate file not found!"
    exit 1
fi

echo "[Certbot Hook] Hook completed successfully at $(date)"
