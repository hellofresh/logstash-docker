#!/bin/bash

# Make sure logstashbrcvr is running before logstash starts.
sv start logstashbrcvr || exit 1

# Start logstash itself.
cd /opt/logstash
exec 2>&1
exec /sbin/setuser logstash bin/logstash -f /etc/logstash/conf.d
