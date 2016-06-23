FROM quay.io/hellofresh/logstash-docker:wespi-0.3.0

# Use baseimage-docker's init system.
# Reference: https://github.com/phusion/baseimage-docker#using-baseimage-docker-as-base-image
CMD ["/sbin/my_init"]

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

# Expose Consul HTTP and Serf LAN ports.
EXPOSE 8500
EXPOSE 8301

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
