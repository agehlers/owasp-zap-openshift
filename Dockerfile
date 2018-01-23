# This dockerfile builds the zap stable release
FROM registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift
MAINTAINER Deven Phillips <deven.phillips@redhat.com>

USER root

## Disable hard-coded Red Hat repo in base image
RUN rm -rf /etc/yum.repos.d/*

RUN yum install -y net-tools python27-python-pip \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel wget curl \
    xmlstarlet git x11vnc gettext tar \
    xorg-x11-server-Xvfb openbox xterm \
    firefox nss_wrapper nss_wrapper git && \
    yum clean all
    
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py

RUN pip install --upgrade pip
RUN pip install zapcli
# Install latest dev version of the python API
RUN pip install python-owasp-zap-v2.4

RUN mkdir -p /zap/wrk
ADD zap /zap/

RUN mkdir -p /var/lib/jenkins/.vnc

# Copy the entrypoint
COPY configuration/* /var/lib/jenkins/
COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap:$PATH
ENV ZAP_PATH /zap/zap.sh
ENV HOME /var/lib/jenkins

# Default port for use with zapcli
ENV ZAP_PORT 8080

COPY policies /var/lib/jenkins/.ZAP/policies/
COPY .xinitrc /var/lib/jenkins/

WORKDIR /zap
# Download and expand the latest stable release 
RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions-dev.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -q --content-disposition -i - -O - | tar zx --strip-components=1 && \
    curl -s -L https://bitbucket.org/meszarv/webswing/downloads/webswing-2.3-distribution.zip | jar -x && \
    touch AcceptedLicense
ADD webswing.config /zap/webswing-2.3/webswing.config

RUN chown root:root /zap -R && \
    chown root:root -R /var/lib/jenkins && \
    chmod 777 /var/lib/jenkins -R && \
    chmod 777 /zap -R

WORKDIR /var/lib/jenkins

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
USER 1001
