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
    libssl-dev libwebp-dev wget curl tomcat9 \
    && apt-get clean

# We don't need to build guacamole-server in this container
# as it runs in a separate container (guacd)

# Download and deploy guacamole web application
RUN wget https://downloads.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war \
    && mv guacamole-${GUAC_VERSION}.war /var/lib/tomcat9/webapps/guacamole.war

# Set environment variables for Tomcat
ENV CATALINA_HOME=/usr/share/tomcat9
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create configuration directory
RUN mkdir -p /etc/guacamole /usr/share/tomcat9/.guacamole && \
    # Fix Tomcat permissions
    chmod +x /usr/share/tomcat9/bin/*.sh

# Add default configuration files
COPY guacamole.properties /etc/guacamole/
COPY user-mapping.xml /etc/guacamole/

# Link configuration directory
RUN ln -s /etc/guacamole /usr/share/tomcat9/.guacamole

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["/usr/share/tomcat9/bin/catalina.sh", "run"]