FROM quay.io/hellofresh/logstash-docker:wespi-0.1.0

#
# Install Logstash 2.2
#

# Shamelessly copied from official Logstash 2.2 Dockerfile
# Reference: https://github.com/docker-library/logstash/blob/master/2.2/Dockerfile
# the "ffi-rzmq-core" gem is very picky about where it looks for libzmq.so
RUN mkdir -p /usr/local/lib \
  && ln -s /usr/lib/*/libzmq.so.3 /usr/local/lib/libzmq.so

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
  && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
  && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true

# https://www.elastic.co/guide/en/logstash/2.0/package-repositories.html
# https://packages.elasticsearch.org/GPG-KEY-elasticsearch
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV LOGSTASH_MAJOR 2.2
ENV LOGSTASH_VERSION 1:2.2.2-1

RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_MAJOR}/debian stable main" > /etc/apt/sources.list.d/logstash.list

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends logstash=$LOGSTASH_VERSION unzip jq

# Update PATH to include Logstash binaries.
ENV PATH=${PATH}:/opt/logstash/bin

# Cleanup APT.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy logstash config into place.
COPY conf/logstash.conf /etc/logstash/conf.d/logstash.conf

# Fulfill prerequisites for example logstash configuration in 'conf/logstash.conf'. 
RUN touch /tmp/inputfile.log && \
    touch /tmp/outputfile.log && \
    chmod go+w /tmp/*.log

# Copy runit scripts into place.
COPY logstash_service.sh /etc/service/logstash/run

# Fetch logstash-output-amazon_es plugin (which get's installed through an external process later on).
RUN mkdir /tmp/plugin && \
    wget https://github.com/hellofresh/logstash-output-amazon_es/releases/download/v0.3/logstash-output-amazon_es-0.3-java.gem -O /tmp/plugin/logstash-output-amazon_es-0.3-java.gem

# Use baseimage-docker's init system.
# Reference: https://github.com/phusion/baseimage-docker#using-baseimage-docker-as-base-image
CMD ["/sbin/my_init"]

# Allow Beat connections over TCP port 5044.
EXPOSE 5044

################################################################################################
# logstashbrcvr a.k.a. Logstash Heartbeat Receiver
# Allows monitoring of Logstash functionality based on heartbeat input plugin [1]
# in combination with a small Golang binary 'logstashbrcvr' [2].
# [1] https://www.elastic.co/guide/en/logstash/current/plugins-inputs-heartbeat.html
# [2] https://github.com/hellofresh/logstashbrcvr

# - Create dedicated user to run the monitoring util binary,
# - create log directory for logstashbrcvr,
# - change ownership of log directory,
# - fetch logstashbrcvr binary and put it into the right place,
# - make logstashbrcvr executable.
RUN adduser --system --no-create-home --shell /bin/false logstashbrcvr && \
    mkdir /var/log/logstashbrcvr && \
    chown logstashbrcvr:root /var/log/logstashbrcvr && \
    cd /usr/local/bin && \
    wget https://github.com/hellofresh/logstashbrcvr/releases/download/v0.0.1/logstashbrcvr.linux-x86-64 -O logstashbrcvr.linux && \
    chmod +x logstashbrcvr.linux

# Create runit service defintions for logstashbrcvr.
COPY ./logstashbrcvr /etc/service/logstashbrcvr

# Move logging configuration to right place.
RUN mv /etc/service/logstashbrcvr/log/config /var/log/logstashbrcvr/config

#########
#
#  Consul (agent)
#
#########

# Fetch consul binary.
RUN wget -O /usr/local/bin/consul_0.6.4_linux_amd64.zip https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip && \
    cd /usr/local/bin && \
    unzip /usr/local/bin/consul_0.6.4_linux_amd64.zip && \
    chmod +x /usr/local/bin/consul && \
    rm /usr/local/bin/consul_0.6.4_linux_amd64.zip

# Create consul data dir.
RUN mkdir -p /var/consul/data

# Copy supervise run scripts into place.
COPY consul_service.sh /etc/service/consul/run

# Copy supervise final script into place.
COPY consul_service_final.sh /etc/service/consul/finish

# Add configuration directory for Consul services.
RUN mkdir /etc/consul.d

# Expose Consul WebUI, HTTP, RPC, DNS endpoints.
EXPOSE 8500

# Consul agent configuration volume.
# Do not use a volume here because it is not working with the serverspec driver 
# `specinfra-backend-docker_compose` (Git SHA ID: ff85800) [1] which uses `docker-compose-api` (v1.1.2) [2]
# which uses `docker-api` [3]. See related bug report: https://github.com/mauricioklein/docker-compose-api/issues/33
# [1] https://github.com/zuazo/specinfra-backend-docker_compose
# [2] https://github.com/mauricioklein/docker-compose-api
# [3] https://github.com/swipely/docker-api
#VOLUME ["/etc/consul.d"]

# Create run-once runit service to save the provided service defintion from the environment variable
# into a configuration file which then gets consumed by Consul agent.
# Note: The service runs once and then removes itself from supervision. 

# Create service directory, service files and let know runit about the new service via creation of the symlink.
RUN mkdir /etc/sv/consul_service_config && \
    echo '#!/bin/bash' >> /etc/sv/consul_service_config/run && \
    echo 'exec echo $CONSUL_SERVICE_CONFIG > /etc/consul.d/logstash.json' >> /etc/sv/consul_service_config/run && \
    chmod +x /etc/sv/consul_service_config/run && \
    echo '#!/bin/bash' >> /etc/sv/consul_service_config/finish && \
    echo 'rm /etc/service/consul_service_config' >> /etc/sv/consul_service_config/finish && \
    chmod +x /etc/sv/consul_service_config/finish && \
    ln -s /etc/sv/consul_service_config/ /etc/service/consul_service_config
