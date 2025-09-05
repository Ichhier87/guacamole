# Use an ARM-compatible base image with Java and build tools
FROM arm64v8/ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GUAC_VERSION=1.5.5

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin \
    libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev \
    libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev \
    libssl-dev libwebp-dev wget curl tomcat9 \
    && apt-get clean

# Download and build guacamole-server
RUN wget https://downloads.apache.org/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz \
    && tar -xzf guacamole-server-${GUAC_VERSION}.tar.gz \
    && cd guacamole-server-${GUAC_VERSION} \
    && ./configure \
    && make \
    && make install \
    && ldconfig \
    && cd .. \
    && rm -rf guacamole-server-${GUAC_VERSION}*

# Download and deploy guacamole web application
RUN wget https://downloads.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war \
    && mv guacamole-${GUAC_VERSION}.war /var/lib/tomcat9/webapps/guacamole.war

# Create configuration directory
RUN mkdir -p /etc/guacamole /usr/share/tomcat9/.guacamole

# Add default configuration files
COPY guacamole.properties /etc/guacamole/
COPY user-mapping.xml /etc/guacamole/

# Link configuration directory
RUN ln -s /etc/guacamole /usr/share/tomcat9/.guacamole

# Expose ports
EXPOSE 8080 4822

# Start services
CMD service guacd start && catalina.sh run