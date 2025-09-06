# Use an ARM-compatible base image with Java and build tools
FROM arm64v8/ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GUAC_VERSION=1.6.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin \
    libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev \
    libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev \
    libssl-dev libwebp-dev wget curl tomcat9 unzip \
    && apt-get clean

# Copy Tomcat configuration files
RUN mkdir -p /usr/share/tomcat9/conf && \
    cp -r /etc/tomcat9/* /usr/share/tomcat9/conf/ || true

# Copy our backup server.xml if the copy failed
COPY tomcat-config/server.xml /usr/share/tomcat9/conf/

# We don't need to build guacamole-server in this container
# as it runs in a separate container (guacd)

# Download and deploy guacamole web application
RUN mkdir -p /var/lib/tomcat9/webapps/guacamole && \
    wget https://downloads.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war \
    && unzip -o guacamole-${GUAC_VERSION}.war -d /var/lib/tomcat9/webapps/guacamole/ \
    && rm guacamole-${GUAC_VERSION}.war

# Set environment variables for Tomcat
ENV CATALINA_HOME=/usr/share/tomcat9
ENV CATALINA_BASE=/usr/share/tomcat9
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create configuration directory
RUN mkdir -p /etc/guacamole /usr/share/tomcat9/.guacamole && \
    # Fix Tomcat permissions
    chmod +x /usr/share/tomcat9/bin/*.sh && \
    # Create necessary Tomcat directories
    mkdir -p /usr/share/tomcat9/webapps /usr/share/tomcat9/work /usr/share/tomcat9/temp /usr/share/tomcat9/logs && \
    # Set correct permissions
    chown -R root:root /usr/share/tomcat9

# Add default configuration files
COPY guacamole.properties /etc/guacamole/
COPY user-mapping.xml /etc/guacamole/

# Link configuration directory
RUN ln -s /etc/guacamole /usr/share/tomcat9/.guacamole

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["/usr/share/tomcat9/bin/catalina.sh", "run"]