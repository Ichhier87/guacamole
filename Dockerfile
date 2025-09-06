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
RUN mkdir -p /usr/share/tomcat9/webapps && \
    cd /usr/share/tomcat9/webapps && \
    wget https://downloads.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war \
    && mv guacamole-${GUAC_VERSION}.war guacamole.war

# Set GUACAMOLE_HOME and ensure it exists with proper permissions
ENV GUACAMOLE_HOME=/etc/guacamole
RUN mkdir -p ${GUACAMOLE_HOME} && \
    chown -R root:root ${GUACAMOLE_HOME} && \
    chmod 755 ${GUACAMOLE_HOME}

# Set environment variables for Tomcat
ENV CATALINA_HOME=/usr/share/tomcat9
ENV CATALINA_BASE=/usr/share/tomcat9
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create Tomcat directories and set permissions
RUN mkdir -p /usr/share/tomcat9/webapps && \
    mkdir -p /usr/share/tomcat9/work && \
    mkdir -p /usr/share/tomcat9/temp && \
    mkdir -p /usr/share/tomcat9/logs && \
    chmod +x /usr/share/tomcat9/bin/*.sh && \
    chown -R tomcat:tomcat /usr/share/tomcat9

# Debug: List contents of build context
RUN pwd && ls -la

# Add configuration files and set proper permissions
COPY guac-config/guacamole.properties ${GUACAMOLE_HOME}/
COPY guac-config/user-mapping.xml ${GUACAMOLE_HOME}/

# Verify files were copied and set permissions
RUN ls -la ${GUACAMOLE_HOME}/ && \
    chown -R root:root ${GUACAMOLE_HOME}/* && \
    chmod 644 ${GUACAMOLE_HOME}/*

# Fix permissions again after copying config files
RUN chown -R tomcat:tomcat /etc/guacamole

# Switch to tomcat user
USER tomcat

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat with debugging enabled
CMD CATALINA_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n" /usr/share/tomcat9/bin/catalina.sh run