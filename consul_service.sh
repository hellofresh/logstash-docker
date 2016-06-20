#!/bin/bash

exec /usr/local/bin/consul agent -client 0.0.0.0 -config-dir /etc/consul.d -data-dir /var/consul/data -encrypt ${CONSUL_ENCRYPT} -join ${CONSUL_START_JOIN}
