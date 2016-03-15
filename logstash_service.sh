#!/bin/bash

cd /opt/logstash
exec /sbin/setuser logstash bin/logstash -f /etc/logstash/conf.d/logstash.conf
