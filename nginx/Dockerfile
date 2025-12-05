FROM nginx:1.24-alpine

# Create necessary directories
RUN mkdir -p /var/www/test /var/www/certbot

# Copy configuration and test files
COPY conf.d/default.conf /etc/nginx/conf.d/
COPY test/firewall-test.txt /var/www/test/

# Copy certificate reload watcher and entrypoint scripts
COPY reload-watcher.sh /usr/local/bin/reload-watcher.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Set permissions
RUN chmod -R 755 /var/www \
    && chmod -R 755 /etc/nginx/conf.d \
    && mkdir -p /etc/letsencrypt \
    && chown -R nginx:nginx /etc/letsencrypt \
    && chmod +x /usr/local/bin/reload-watcher.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Run as root to bind to privileged ports
# This is needed for SSL certificate access

# Expose ports
EXPOSE 80 443

# Use custom entrypoint that starts both nginx and the certificate watcher
CMD ["/usr/local/bin/entrypoint.sh"]
