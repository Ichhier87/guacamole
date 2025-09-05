FROM nginxinc/nginx-unprivileged:1.24-alpine-slim

USER root
# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration files
COPY conf.d/ /etc/nginx/conf.d/

# Copy test files
COPY test/ /var/www/test/

# Create directories for certbot and fix permissions
RUN mkdir -p /var/www/certbot && \
    # Fix permissions for nginx user
    chown -R nginx:nginx /var/www && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Switch back to non-root user
USER nginx

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
