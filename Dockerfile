FROM quay.io/hellofresh/hf-javaimage

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
  && apt-get install -y --no-install-recommends logstash=$LOGSTASH_VERSION

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
