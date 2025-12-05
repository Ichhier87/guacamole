FROM nginx:1.24-alpine

# Create necessary directories
RUN mkdir -p /var/www/test /var/www/certbot

# Copy configuration and test files
COPY conf.d/default.conf /etc/nginx/conf.d/
COPY test/firewall-test.txt /var/www/test/

# Copy certificate reload watcher script
COPY reload-watcher.sh /usr/local/bin/reload-watcher.sh

# Set permissions
RUN chmod -R 755 /var/www \
    && chmod -R 755 /etc/nginx/conf.d \
    && mkdir -p /etc/letsencrypt \
    && chown -R nginx:nginx /etc/letsencrypt \
    && chmod +x /usr/local/bin/reload-watcher.sh

# Create startup script inline
RUN echo '#!/bin/sh' > /docker-entrypoint.d/99-start-watcher.sh && \
    echo '/usr/local/bin/reload-watcher.sh &' >> /docker-entrypoint.d/99-start-watcher.sh && \
    chmod +x /docker-entrypoint.d/99-start-watcher.sh

# Run as root to bind to privileged ports
# This is needed for SSL certificate access

# Expose ports
EXPOSE 80 443

# Use default nginx entrypoint (which will run our watcher script)
CMD ["nginx", "-g", "daemon off;"]
