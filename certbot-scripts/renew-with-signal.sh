#!/bin/sh
# Enhanced Certbot Renewal Script with Reload Signal

set -e

echo "[Certbot Renew] Starting certificate renewal check at $(date)"

# Run certbot renewal
if certbot renew --deploy-hook "echo 'Certificate renewed!' && touch /etc/letsencrypt/reload-required"; then
    echo "[Certbot Renew] Renewal check completed successfully"

    # Fix permissions
    echo "[Certbot Renew] Setting correct permissions..."
    chmod -R 755 /etc/letsencrypt
    find /etc/letsencrypt -type f -exec chmod 644 {} \; 2>/dev/null || true

    # Check if renewal flag was created
    if [ -f "/etc/letsencrypt/reload-required" ]; then
        echo "[Certbot Renew] ✓ Certificate was renewed - reload signal created"
    else
        echo "[Certbot Renew] No renewal needed at this time"
    fi
else
    echo "[Certbot Renew] ✗ ERROR: Renewal failed!"
    exit 1
fi

echo "[Certbot Renew] Completed at $(date)"
