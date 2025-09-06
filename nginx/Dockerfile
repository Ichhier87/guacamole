FROM nginxinc/nginx-unprivileged:1.24-alpine-slim

USER root
# Create necessary directories
RUN mkdir -p /var/www/test /var/www/certbot /etc/letsencrypt

# Copy configuration and test files
COPY conf.d/default.conf /etc/nginx/conf.d/
COPY test/firewall-test.txt /var/www/test/

# Set permissions
RUN chown -R nginx:nginx /var/www && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    chown -R nginx:nginx /etc/letsencrypt && \
    chmod -R 755 /etc/letsencrypt

# Switch back to non-root user
USER nginx

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
