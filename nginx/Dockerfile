FROM nginx:1.24-alpine

# Create necessary directories
RUN mkdir -p /var/www/test /var/www/certbot

# Copy configuration and test files
COPY conf.d/default.conf /etc/nginx/conf.d/
COPY test/firewall-test.txt /var/www/test/

# Set permissions
RUN chmod -R 755 /var/www \
    && chmod -R 755 /etc/nginx/conf.d \
    && mkdir -p /etc/letsencrypt \
    && chown -R nginx:nginx /etc/letsencrypt

# Run as root to bind to privileged ports
# This is needed for SSL certificate access

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
